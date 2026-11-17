# DevOps Lab — Session 1 — Answers
## Question 1 — Why forbid direct pushes to `main`?

main is the shared, deployable branch, so it should only hold tested, reviewed code. Forbidding direct pushes forces every change through a Pull Request, where CI runs build and tests before merge unlocks, so a broken commit can't land. It also gives a diff to review, a traceable history (each main commit maps to a PR), and protection against accidental force-pushes or branch deletion. It prevents races when several people push at once, since each change is merged against the current main.

The trade-off is small friction: a one-line hotfix needs a branch and a PR instead of a direct push. That's the intended trade, slightly slower but much safer, and it's what steps 1.5 and 1.6 set up so the CI pipeline in Part 3 can attach to the PR and prove the gate works before anything reaches main.


## Question 2: What is the difference between an image and a container?

An image is a read-only template that contains the application code, runtime, system libraries, and dependencies, and is used to create containers . A container is a runtime instance created from an image; it is an isolated process with its own writable layer that can be started, stopped, and deleted . Simply put, an image is the "blueprint," and a container is the "running instance" after the blueprint is executed. An image is immutable, while a container has a lifecycle.

## Question 3: Compared to non-slim base images, what changes in the image size?

Using node:20-alpine yields a significant size reduction. The standard node:20 (based on Debian) image can reach over 300MB or even 1.1GB . In contrast, the Alpine version is typically only 40–60MB, or approximately 130MB after including your application dependencies . The main reason is that Alpine uses musl libc and BusyBox, and the base system itself is only about 5MB, whereas Debian's base footprint exceeds 100MB .
