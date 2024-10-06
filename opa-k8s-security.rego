package main

deny[msg] {
  input.kind = "Service"
  not input.spec.type = "NodePort"
  msg = "Service type should be NodePort"
}

deny[msg] {
  input.kind = "Deployment"
  not input.spec.template.spec.containers[0].securityContext.runAsNonRoot = true
  msg = "Containers must not run as root - use runAsNonRoot wihin container security context"
}

deny[msg] {
  input.kind = "Deployment"
  container := input.spec.template.spec.containers[_]
  not container.resources.limits.cpu
  msg = sprintf("Container %s does not have CPU limit set", [container.name])
}

deny[msg] {
  input.kind = "Deployment"
  container := input.spec.template.spec.containers[_]
  not container.resources.limits.memory
  msg = sprintf("Container %s does not have memory limit set", [container.name])
}

