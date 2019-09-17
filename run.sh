#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo $DIR
sbcl --script $DIR/idyom/apps/mirex.lisp $DIR
