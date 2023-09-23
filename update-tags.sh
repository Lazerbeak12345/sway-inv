#!/bin/bash
case "$4" in
	"") location=HEAD ;;
	*) location=$4 ;;
esac
git tag -f $1 $location
git tag -f $1.$2 $location
git tag -f $1.$2.$3 $location
