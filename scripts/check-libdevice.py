import os


def check_libdevice_with_cuda_path():
    cuda_path = os.environ.get("CUDA_PATH")
    if not cuda_path:
        print("CUDA_PATH environment variable not set")
        return False

    libdevice_paths = [
        os.path.join(cuda_path, "nvvm", "libdevice", "libdevice.10.bc"),
        os.path.join(cuda_path, "lib64", "libdevice.10.bc"),
    ]

    for path in libdevice_paths:
        if os.path.exists(path):
            print(f"Found libdevice at: {path}")
            return True

    print("libdevice not found in CUDA_PATH locations")
    return False


if check_libdevice_with_cuda_path():
    print("libdevice is available")
else:
    print("libdevice is not available")
