#!/bin/sh

systemtap/ipiprof.stp > ipiprof.dump
./mkipigraph.plx < ipiprof.dump
