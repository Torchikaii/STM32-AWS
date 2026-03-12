# Phase 1: CI/CD Foundation

**Goal:** Fix and solidify the CI/CD pipeline to work for any STM32 MCU by implementing license automation

**Prerequisites:**
- STM32CubeMX installed in Docker image
- GitHub Actions workflow file exists
- Test project (test439/) with .ioc file exists

---

## Critical Issue

The current CI/CD pipeline **hangs indefinitely** when running `swmgr install stm32cube_f4_1.28.2 ask` because STM32CubeMX displays a GUI license acceptance dialog that cannot be interacted with in headless CI environments.

---

### Task 1: Create expect Script for License Automation

**Description:** Create an expect script that automates the STM32CubeMX license dialog when installing firmware packages. The script should wait for the dialog, press Tab to select "Yes", and press Enter to accept.

**Files to modify:**
- `.github/workflows/stm32_generate_code.yml` - Add expect installation step
- `Dockerfile` - Add expect package

**New files to create:**
- `scripts/expect-license.exp` - Expect script to handle license dialog

**Validation:**
- [ ] Script can be invoked with `expect scripts/expect-license.exp`
- [ ] Script handles timeout gracefully (exits with error if dialog doesn't appear)
- [ ] Script works in xvfb environment

**Estimated complexity:** Medium

---

### Task 2: Create CubeMX Wrapper Script

**Description:** Create a wrapper script (`cubemx-runner.sh`) that runs STM32CubeMX with the expect automation. This provides a clean interface for both local and CI usage.

**Files to modify:**
- `Dockerfile` - Add wrapper script as entrypoint or convenient command

**New files to create:**
- `docker/cubemx-runner.sh` - Wrapper script that combines xvfb-run + expect + STM32CubeMX

**Validation:**
- [ ] Script accepts generate_script.txt as argument
- [ ] Script runs without hanging
- [ ] Script logs output for debugging

**Estimated complexity:** Low

---

### Task 3: Update GitHub Actions Workflow

**Description:** Modify the CI workflow to use the expect automation instead of direct STM32CubeMX invocation.

**Files to modify:**
- `.github/workflows/stm32_generate_code.yml` - Update Run STM32CubeMX step to use wrapper

**Validation:**
- [ ] Workflow runs without hanging
- [ ] F4 firmware package is installed successfully
- [ ] Code generation completes

**Estimated complexity:** Medium

---

### Task 4: Test CI Pipeline End-to-End

**Description:** Trigger the CI workflow manually to verify the complete pipeline works.

**Validation:**
- [ ] GitHub Actions workflow runs successfully
- [ ] Build artifacts (ELF, BIN, HEX) are generated
- [ ] Size checks pass
- [ ] Artifacts are uploaded

**Estimated complexity:** Low

---

## Dependencies

```
Task 1 ──┐
         ├──► Task 3 ──► Task 4
Task 2 ──┘
```

---

## Implementation Notes

### expect Script Pattern
```tcl
#!/usr/bin/expect -f
set timeout 60
spawn xvfb-run -a /opt/STM32CubeMX/STM32CubeMX -q /path/to/script.txt
expect "License Agreement"
send "\t"  ;# Tab to select Yes
send "\r"  ;# Enter to confirm
expect eof
```

### Alternative: xdotool Approach
If expect fails, use xdotool:
```bash
xvfb-run -a -s "-screen 0 1024x768x24" \
  xdotool key Tab+Tab+Return &
STM32CubeMX -q script.txt
```

---

## Success Criteria

- [ ] CI pipeline completes without hanging
- [ ] Code generation works for STM32F439
- [ ] Build produces valid ELF/BIN/HEX
- [ ] Solution works for any STM32 MCU family (not just F4)
