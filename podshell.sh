#!/bin/bash
# podshell v0.1
# drops down to pod shells in a semi-interactive fashion
# RS Nov 22
# To DO:
# - don't print num on headers
# - error catching or input filtering


echo "-------------------------------------"
echo "--            podshell             --"
echo "-------------------------------------"
echo

# get list of namespaces and prepend a number before each line
# to do: don't print number before header
i=0
k3s kubectl get namespaces | while read line; do echo "[$i] $line"; ((i++)); done
echo

# which namespace do we want to work with
echo "Which namespace does the pod belong to?"
read namenum
# correct for header line
((namenum++))

# load the namespace into a var
namespace=$(k3s kubectl get namespaces | sed -n "$namenum p" | awk '{print $1}')

# now get the pods of that namespace and prepend number
# to-do: i=0 not really necessary
i=0
k3s kubectl get -n $namespace pods | while read line; do echo "[$i] $line"; ((i++)); done
echo

# which pod do we want to drop down into
echo "Which pod do want to shell into?"
read podnum
# correct for header line
((podnum++))

# load the pod name into a var
podname=$(k3s kubectl get -n $namespace pods | sed -n "$podnum p" | awk '{print $1}')

# exec shell
k3s kubectl exec -n $namespace --stdin --tty $podname -- /bin/bash
