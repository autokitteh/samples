package samples

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"os/exec"
	"path"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
)

const akURL = "http://localhost:9980"

func TestMain(m *testing.M) {
	exe, err := exec.LookPath("ak")
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: can't find `ak` in PATH (%s)\n", err)
		os.Exit(1)
	}

	cmd := exec.Command("ak", "version")
	out, err := cmd.CombinedOutput()

	if err != nil {
		fmt.Fprintf(os.Stderr, "error: can't get `ak` version (%s)\n", err)
		os.Exit(1)
	}
	version := string(out[:len(out)-1]) // trim \n

	slog.Info("ak", "exe", exe, "version", version)

	code := m.Run()
	os.Exit(code)
}

func waitFor(t *testing.T, url string, timeout time.Duration) {
	start := time.Now()
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	require.NoError(t, err, "create request")

	for time.Since(start) <= timeout {
		resp, err := http.DefaultClient.Do(req)
		if err == nil && resp.StatusCode == http.StatusOK {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}

	require.FailNowf(t, "%q not ready after %v", url, timeout)
}

func startAK(t *testing.T) {
	cmd := exec.Command("ak", "up", "-m", "dev")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	err := cmd.Start()
	require.NoError(t, err, "run `ak`")
	t.Cleanup(func() {
		if err := cmd.Process.Kill(); err != nil {
			t.Logf("warning: can't kill %d - %s", cmd.Process.Pid, err)
		}
	})

	waitFor(t, akURL, time.Second)
}

func deploy(t *testing.T, rootPath string) {
	manifest := path.Join(rootPath, "autokitteh.yaml")
	cmd := exec.Command("ak", "deploy", "-m", manifest, "-d", rootPath)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	require.NoErrorf(t, err, "deploy manifest in %q", rootPath)
}

func testCtx(t *testing.T) (context.Context, context.CancelFunc) {
	d, ok := t.Deadline()
	if ok {
		return context.WithDeadline(context.Background(), d)
	}

	return context.WithTimeout(context.Background(), time.Second)
}

type SessionState byte

const (
	CompletedState SessionState = iota + 1
	ErrorState
)

func sessionState(t *testing.T) SessionState {
	cmd := exec.Command("ak", "session", "log", "-j")
	data, err := cmd.CombinedOutput()
	require.NoError(t, err, "session log")

	// {"t":"2024-04-08T13:04:51.884583388Z","state":{"created":{}}}
	// ..."state":{"running":{"run_id":"run_4p7gjjnxd827qbz7kc4g4bancx"}}}
	// ..."state":{"completed":{"prints": ...
	// ..."state":{"error":{"prints": ...
	dec := json.NewDecoder(bytes.NewReader(data))
	for {
		var result struct {
			State struct {
				Completed json.RawMessage
				Error     json.RawMessage
			}
		}
		err := dec.Decode(&result)
		if errors.Is(err, io.EOF) {
			break
		}
		require.NoError(t, err, "read session")

		switch {
		case result.State.Completed != nil:
			return CompletedState
		case result.State.Error != nil:
			return ErrorState
		}
	}

	require.FailNow(t, "session not finished")
	return 0 // Make compiler happy
}

func Test_http(t *testing.T) {
	startAK(t)
	deploy(t, "../http")

	ctx, cancel := testCtx(t)
	defer cancel()

	url := fmt.Sprintf("%s/%s", akURL, "/http/http_sample/trigger_url_path")
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	require.NoError(t, err, "create request")
	resp, err := http.DefaultClient.Do(req)
	require.NoErrorf(t, err, "call %q", url)
	require.Equalf(t, http.StatusOK, resp.StatusCode, "%q: bad status: %s", url, resp.Status)

	time.Sleep(time.Second) // TODO: Find a way to poll on workflow

	state := sessionState(t)
	require.Equal(t, CompletedState, state, "workflow state")
}
