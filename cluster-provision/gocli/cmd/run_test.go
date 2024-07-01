package cmd

import "testing"

type sshStub struct {
	err  error
	cmds []string
}

func (ssh *sshStub) SSH(cmd string, stdout bool) (string, error) {
	if !stdout {
		panic("not implemented")
	}
	ssh.cmds = append(ssh.cmds, cmd)
	return "", ssh.err
}

func TestConfigureNodes(t *testing.T) {
	sshClient := sshStub{}

	prefix, nodeName := "", ""
	f := func(p, n string) error {
		prefix, nodeName = p, n
		return nil
	}
	configureNodes(&sshClient, true, "somePrefix", "node", f)

	if prefix != "somePrefix" {
		t.Fatal("Prefix should be `somePrefix`")
	}

	if nodeName != "node" {
		t.Fatal("nodeName should be `node`")
	}

	if len(sshClient.cmds) == 1 && sshClient.cmds[0] != "sudo fips-mode-setup --enable && ( ssh.sh sudo reboot || true )" {
		t.Fatal("unexpected command: ", sshClient.cmds)
	}
}
