# Running BankLite Lab on Windows

Tested path: Windows 10 (22H2) or Windows 11, Docker Desktop with the WSL2 backend, PowerShell.
Do this before the session; the first build needs internet and takes several minutes.

## 1. Check the laptop

* 8 GB RAM recommended (4 GB minimum) and at least 5 GB free disk.
* Virtualisation must be on. Open Task Manager, Performance, CPU and look for
  "Virtualization: Enabled". If it says Disabled, enable Intel VT-x or AMD SVM in the BIOS.

## 2. Install WSL2

Open PowerShell **as Administrator**:

```powershell
wsl --install
```

Restart when asked. Then check, in a normal PowerShell window:

```powershell
wsl --status        # should show "Default Version: 2"
```

If it asks for an update, run `wsl --update`.

## 3. Install Docker Desktop

1. Download it from https://www.docker.com/products/docker-desktop/ and install it with
   "Use WSL 2 instead of Hyper-V" ticked.
2. Start Docker Desktop and wait until it shows "Engine running".
3. Check it in PowerShell:

```powershell
docker run --rm hello-world     # prints "Hello from Docker!"
```

## 4. Install Git

Download Git for Windows from https://git-scm.com/download/win and keep the default options.
The repository pins Linux line endings (`.gitattributes`), so the default settings are fine.

## 5. Build and check the lab

Use a normal (not Administrator) PowerShell window:

```powershell
cd $HOME\Desktop
git clone https://github.com/preet-qclair/banklite-lab.git
cd banklite-lab
docker build -t banklite-lab .
mkdir out
docker run --rm -it -v "${PWD}/out:/lab/out" banklite-lab ./check.sh
```

The last line should be `ALL OK`.

## 6. During the session

Start the lab shell from the `banklite-lab` folder:

```powershell
docker run --rm -it -v "${PWD}/out:/lab/out" banklite-lab
```

Type `exit` to leave. Files you write to `/lab/out` inside the container appear in the `out`
folder, which you can open in File Explorer. Open `worksheet\prioritise.xlsx` in Excel or
LibreOffice for Lab 4.

Notes:

* Leave out the `--user ...` part shown in the Linux commands; Docker Desktop handles file
  ownership itself.
* Use PowerShell, not Command Prompt. In Command Prompt, replace `${PWD}` with `%cd%`.
* Run every `docker run` from inside the `banklite-lab` folder, so that `out` is the right folder.

## 7. Facilitator rehearsal (optional)

```powershell
docker run --rm --network none -v "${PWD}/out:/lab/out" banklite-lab ./facilitator/run-all.sh
```

The last line should read `union: 8/13 found, 2 partial, 3 missed`.

## Offline copy

To copy the built image to a USB stick, and to load it on another laptop:

```powershell
docker save banklite-lab -o banklite-lab.tar
docker load -i banklite-lab.tar
```

## Problems

See the Troubleshooting table in the [README](../README.md#troubleshooting).
