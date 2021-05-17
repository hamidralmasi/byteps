#!/bin/bash

path="`dirname $0`"
set -x
export PYTHONPATH=/opt/tiger/byteps:$PYTHONPATH
export PATH=~/.local/bin:$PATH
export BYTEPS_OMP_THREAD_PER_GPU=0
export LD_LIBRARY_PATH=$UCX_HOME/lib:$LD_LIBRARY_PATH
export DMLC_ENABLE_RDMA=${DMLC_ENABLE_RDMA:-0}
export DMLC_NUM_WORKER=2
export DMLC_NUM_SERVER=$DMLC_NUM_WORKER
export DMLC_PS_ROOT_URI=${DMLC_PS_ROOT_URI:-10.188.182.139}
export DMLC_PS_ROOT_PORT=${DMLC_PS_ROOT_PORT:-22163}
export DMLC_NODE_HOST=${DMLC_NODE_HOST:-$DMLC_PS_ROOT_URI}
export BYTEPS_LOCAL_SIZE=${BYTEPS_LOCAL_SIZE:=1}
export BYTEPS_LOCAL_RANK=$(($2%$BYTEPS_LOCAL_SIZE))
export NVIDIA_VISIBLE_DEVICES=0
export BYTEPS_SERVER_DIRECT_RESPONSE=2;
export BYTEPS_WORKER_LOCAL_ROOT=0
export BYTEPS_FORCE_DISTRIBUTED=1
export BYTEPS_PARTITION_BYTES=4096000
export BYTEPS_LOG_LEVEL=${BYTEPS_LOG_LEVEL:-info}
export PS_VERBOSE=${PS_VERBOSE:-0}
export TEST_TYPE=${TEST_TYPE:=tensorflow}
export BYTEPS_TELEMETRY_ON=0
export BYTEPS_UCX_SHORT_THRESH=0
# Note: updated BYTEPS_SOCKET_PATH for cpu allreduce
export BYTEPS_PHY_NODE_ID=$(($2/$BYTEPS_LOCAL_SIZE))
export BYTEPS_SOCKET_PATH=/tmp/node-${BYTEPS_PHY_NODE_ID}
mkdir -p $BYTEPS_SOCKET_PATH

if [ $1 == "scheduler" ]; then
  echo "Launch scheduler"
  DMLC_ROLE=scheduler python3 -c 'import byteps.server'
  exit
fi

export DMLC_WORKER_ID=$2
if [ $1 == "server" ]; then
  echo "Launch server"
  DMLC_ROLE=server python3 -c 'import byteps.server'
  exit
fi

# export GDB=" gdb -ex run --args "
export GDB=" "

if [ $1 == "worker" ] || [ $1 == "joint" ]; then
  export DMLC_ROLE=$1
  if [ "$TEST_TYPE" == "tensorflow" ]; then
    echo "TEST TENSORFLOW ..."
    $GDB python3 $path/test_tensorflow_p2p.py --rank $2
  elif [ "$TEST_TYPE" == "torch" ]; then
    echo "TEST TORCH ..."
    python3 $path/test_torch_p2p.py --rank $2
  else
    echo "Error: unsupported $TEST_TYPE"
    exit 1
  fi
fi