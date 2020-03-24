#!/bin/bash

function link()
{
        db_name=`basename $1`
        if ! [[ -e $db_name ]]; then
                ln -s $1
        fi
        echo $db_name
}

function check_module()
{
	module -v 1> /dev/null 2> /dev/null
	echo $?
}
