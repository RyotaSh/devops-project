# DevOps Lab — Session 2 — Answers

## Question 1 — Role of a namespace
A namespace is a logical partition of a cluster. Names only have to be unique inside one namespace, and it is the scope for quotas, RBAC rules and network policies. We use it here to separate dev, staging and prod in the same cluster. By itself it does NOT give strong security isolation: pods of different namespaces share the same nodes and kernel and can talk to each other over the network by default. Real isolation needs RBAC, NetworkPolicies, ResourceQuotas and Pod Security settings on top.

## Question 2 — Why is a deleted pod recreated?
The pod belongs to a ReplicaSet created by the Deployment. The ReplicaSet controller (inside the kube-controller-manager) constantly compares the desired state (3 replicas) with the real state. When I delete a pod it sees 2 instead of 3 and creates a new one, which the scheduler places on a node. This is the reconciliation loop.

## Question 3 — Readiness vs liveness
Liveness asks "is the container still alive?". If it fails, the kubelet restarts the container. Readiness asks "can the container receive traffic now?". If it fails, the container is not restarted, but the pod is removed from the Service endpoints, so no traffic is sent to it until it is ready again. With a wrong readiness path the pods stay `0/1 Ready` and the Service has no endpoint.

## Question 4 — Are Secrets encrypted?
No. By default a Secret is only base64 encoded (not encrypted) and stored in clear in etcd, so anyone with read access to it, or to etcd, can read it. Improvements: enable encryption at rest for etcd, restrict access with RBAC, and use an external secret manager (Vault, cloud KMS) with External Secrets or Sealed Secrets so no secret is committed in Git.

## Question 5 — Kustomize for hybrid / multi-cloud
The base contains what is common to all environments and each overlay only patches what differs (namespace, replicas, image tag, labels, config). So the same manifests are deployed everywhere and there is no copy-paste drift. A real on-prem cluster differs from a cloud one in: the storage classes, the way a Service of type LoadBalancer gets an IP (MetalLB on-prem vs cloud load balancer), the ingress controller, the identity/IAM integration, the registry access (private registry, pull secrets), the node sizes and the network/firewall rules.

## Question 6 — Why did the broken rollout not take down the app?
A Deployment does a rolling update: it creates a new ReplicaSet and only stops old pods when new ones are Ready. With a non-existent tag the new pods stay in `ErrImagePull` / `ImagePullBackOff` and never become Ready, so the rollout is blocked. Thanks to `maxUnavailable: 0` the old pods (previous ReplicaSet) were kept and kept serving traffic. Then `kubectl rollout undo` goes back to the previous revision. In my test a pod inside the cluster called the Service every 0.2 s during the broken rollout and the undo: 221 requests OK, 0 failed. I saw the same protection in Part 3: with the wrong probe path the new pod never became Ready, so the 3 old pods kept serving.

## Question 7 — From a production pod to commit, reviewer and pipeline
1. `kubectl describe pod` gives the image (tag = commit SHA) and the owner Deployment.
2. The Deployment annotations give the commit SHA, the pipeline run URL, the owner and the ticket.
3. With the SHA, `git log` / GitHub shows the commit, and the Pull Request that merged it, which lists the reviewer(s) and approvals.
4. The pipeline run URL (or the Actions run for that SHA) shows the build, tests and the publish of the image.
This works because the image is tagged with the SHA and not `latest`.

## Question 8 — Why is manual `kubectl edit` in prod a risk?
The change is made directly on the live object: it is not in Git, has no Pull Request, no review, no CI test and no ticket. The cluster no longer matches the repository (drift), the next `kubectl apply` or GitOps sync may silently overwrite it, and it is hard to know who changed what and why (it only appears in the API audit log, if enabled). It also bypasses the approval process. I even got a warning from `kubectl rollout undo`: the live object no longer matches the `last-applied-configuration` annotation, which shows how imperative commands make the cluster drift from Git. Changes should go through Git and the pipeline (GitOps).
