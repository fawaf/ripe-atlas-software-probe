if [ -n "$ATLAS_BASE" ]
then
	BASE_DIR="$ATLAS_BASE"
	export ATLAS_BASE
fi

. /usr/libexec/atlas-probe-scripts/bin/common-pre.sh

# Commands
SET_DATE_FROM_CURRENTTIME_TXT=:
MANUAL_UPGRADE_CMD=:
TRY_UPGRADE_CMD=:
FINDPID_SSH_CMD=findpid_ssh
KILL_PERDS_CMD=kill_perds
KILL_SSH_CMD=kill_ssh
KILL_TELNETD_CMD=kill_telnetd
MOUNT_FS_CMD=:
SETUP_NETWORK_CMD=:
NTPCLIENT_CMD=:
SU_CMD=""
CHOWN_FOR_MSM=:
CHMOD_FOR_MSM=chmod_for_msm
SET_HOSTNAME=:

# For OpenWrt we need telnetd to run as root.
telnetd()
{
	$SU_CMD "$BB_BASE_DIR/usr/sbin/telnetd" "$@"
}

# Various files and directories
: ${HOME:=/usr/libexec/atlas-probe-scripts}; export HOME	# Set HOME if it isn't set

RESOLV_CONF=/etc/resolv.conf
MODE_FILE=$BASE_DIR/state/mode

# Other conf
TELNETD_PORT=2023
DHCP=False

. /usr/libexec/atlas-probe-scripts/bin/arch/openwrt-sw-probe/openwrt-sw-probe-common.sh

# Directories
STATE_DIR=$WRT_BASE_DIR/state; export STATE_DIR
BB_BASE_DIR=/usr/libexec/atlas-probe; export BB_BASE_DIR
BB_BIN_DIR=$BB_BASE_DIR/bin; export BB_BIN_DIR

# Files
REG_SERVERS_SOURCE=$WRT_ETC_DIR/reg_servers.sh

. /usr/libexec/atlas-probe-scripts/bin/arch/linux/linux-functions.sh

chmod_for_msm()
{
	chmod -R g+rwX "$BASE_DIR"/data
}

# Get ethernet address
get_ether_addr

# Set SOS_ID to the hash of the public key
export SOS_ID="H$(hash_ssh_pubkey $BASE_DIR/etc/probe_key.pub)"

# Create ssh keys if they are not there yet.
if [ ! -f "$BASE_DIR"/etc/probe_key ]; then
    name="$(uci -q get system.@system[0].hostname || echo -e openwrt)"
    mkdir -p "$BASE_DIR"/etc
    ssh-keygen -t rsa -b 4096 -P '' -C "$name" -f "$BASE_DIR"/etc/probe_key
    chown -R atlas:atlas "$BASE_DIR"/etc
fi

while :
do
	mode=$(cat "$MODE_FILE")
	case X$mode in
	Xdev|Xtest|Xprod)
		# Okay
		if [ ! -f "$REG_SERVERS" ]
		then
			mkdir -p "$BASE_DIR"/bin
			cp $REG_SERVERS_SOURCE.$mode $REG_SERVERS
		fi
	;;
	*)
		echo "Probe is not configured, mode $mode"
		sos "Imode-$mode"
		sleep 60
		continue
	;;
	esac
	break
done
