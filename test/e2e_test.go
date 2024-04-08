package samples

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/exec"
	"path"
	"regexp"
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

// t:{seconds:1712565862  nanos:324155669}  state:{completed:{prints:" ...
var statusRe = regexp.MustCompile(`}\s+state:{([a-z]+)`)

func sessionState(t *testing.T) string {
	cmd := exec.Command("ak", "session", "log")
	data, err := cmd.CombinedOutput()
	require.NoError(t, err, "session log")

	matches := statusRe.FindAllSubmatch(data, -1)
	require.Greaterf(t, len(matches), 0, "status in:\n%s", string(data))

	match := matches[len(matches)-1]
	return string(match[1])
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
	require.Equal(t, "completed", state, "workflow state")
}
