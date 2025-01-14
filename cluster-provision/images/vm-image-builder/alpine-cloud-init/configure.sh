#!/bin/sh

_step_counter=0
step() {
	_step_counter=$(( _step_counter + 1 ))
	printf '\n\033[1;36m%d) %s\033[0m\n' $_step_counter "$@" >&2  # bold cyan
}

step 'Set up qemu-guest-agent'
cat > /etc/conf.d/qemu-guest-agent <<-EOF
GA_METHOD="virtio-serial"
GA_PATH="/dev/vport1p1"
EOF

step 'Set up timezone'
setup-timezone -z Europe/Prague

step 'Adjust rc.conf'
sed -Ei \
	-e 's/^[# ](rc_depend_strict)=.*/\1=NO/' \
	-e 's/^[# ](rc_logger)=.*/\1=YES/' \
	-e 's/^[# ](unicode)=.*/\1=YES/' \
	/etc/rc.conf

step 'Enable services'
rc-update add acpid default
rc-update add chronyd default
rc-update add crond default
rc-update add termencoding boot
rc-update add qemu-guest-agent default
rc-update add cloud-init default
