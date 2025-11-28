#!/usr/bin/env python

# Copyright (c) 2019 Computer Vision Center (CVC) at the Universitat Autonoma de
# Barcelona (UAB).
#
# This work is licensed under the terms of the MIT license.
# For a copy, see <https://opensource.org/licenses/MIT>.
#
# Adapted for carla-simple-client by Daniel Glaser.

import fnmatch
import os
import subprocess
import sys
from pathlib import Path
from setuptools import setup, Extension

def get_libcarla_extensions():
    """Build libcarla extension for boost.python bindings."""
    
    # Build dependencies first if not already built
    root_dir = Path(__file__).parent.resolve()
    deps_install = root_dir / "deps" / "install"
    
    if not deps_install.exists():
        print("Building dependencies...")
        setup_script = root_dir / "scripts" / "setup-dependencies.sh"
        if setup_script.exists():
            subprocess.run(
                ["bash", str(setup_script)],
                cwd=root_dir,
                check=True,
            )
    
    # Setup paths
    carla_install = deps_install / "libcarla-client"
    include_dir = carla_install / "include"
    lib_dir = carla_install / "lib"
    
    include_dirs = [
        str(include_dir),
        str(include_dir / "system"),
        str(root_dir / "LibCarla" / "source"),
    ]
    
    library_dirs = [str(lib_dir)]
    libraries = []
    
    sources = ['PythonAPI/source/libcarla/libcarla.cpp']

    def walk(folder, file_filter='*'):
        for root, _, filenames in os.walk(folder):
            for filename in fnmatch.filter(filenames, file_filter):
                yield os.path.join(root, filename)

    # Linux-specific configuration
    if os.name == "posix":
        pwd = str(root_dir)
        # Find available boost_python library
        lib_dir_path = os.path.join(pwd, 'deps/install/libcarla-client/lib')
        boost_python_candidates = [
            f"libboost_python{sys.version_info.major}{sys.version_info.minor}.a",
            "libboost_python310.a",  # fallback to available version
            "libboost_python39.a",
            "libboost_python38.a",
        ]
        
        pylib = None
        for candidate in boost_python_candidates:
            if os.path.exists(os.path.join(lib_dir_path, candidate)):
                pylib = candidate
                break
        
        if not pylib:
            raise RuntimeError(f"No boost_python library found in {lib_dir_path}")
        
        print(f"Using boost_python library: {pylib}")
        
        extra_link_args = [
            '-Wl,--whole-archive',
            os.path.join(pwd, 'deps/install/libcarla-client/lib/libcarla_client.a'),
            os.path.join(pwd, 'deps/install/libcarla-client/lib/librpc.a'),
            os.path.join(pwd, 'deps/install/libcarla-client/lib/libboost_filesystem.a'),
            os.path.join(pwd, 'deps/install/libcarla-client/lib/libRecast.a'),
            os.path.join(pwd, 'deps/install/libcarla-client/lib/libDetour.a'),
            os.path.join(pwd, 'deps/install/libcarla-client/lib/libDetourCrowd.a'),
            os.path.join(pwd, 'deps/install/libcarla-client/lib', pylib),
            os.path.join(pwd, 'deps/install/libcarla-client/lib/libpng.a'),
            '-Wl,--no-whole-archive',
            '-lstdc++',
            '-lm',
            '-lpthread',
            '-lz'
        ]
        
        extra_compile_args = [
            '-isystem', os.path.join(pwd, 'deps/install/libcarla-client/include/system'),
            '-fPIC', '-std=c++14',
            '-O3', '-DNDEBUG',
            '-DBOOST_ERROR_CODE_HEADER_ONLY',
            '-DLIBCARLA_WITH_PYTHON_SUPPORT',
            '-DLIBCARLA_IMAGE_WITH_PNG_SUPPORT=true'
        ]
        
    else:
        raise NotImplementedError("Windows builds not yet supported")

    depends = [x for x in walk('PythonAPI/source/libcarla')]
    depends += [x for x in walk('LibCarla/source')]

    def make_extension(name, sources):
        return Extension(
            name,
            sources=sources,
            include_dirs=include_dirs,
            library_dirs=library_dirs,
            libraries=libraries,
            extra_compile_args=extra_compile_args,
            extra_link_args=extra_link_args,
            language='c++14',
            depends=depends)

    print('compiling:\n  - %s' % '\n  - '.join(sources))

    return [make_extension('carla.libcarla', sources)]

# Read long description from README.md
readme_path = Path(__file__).parent / "README.md"
long_description = readme_path.read_text(encoding="utf-8") if readme_path.exists() else ""

setup(
    name='carla-client',
    version='0.9.16',
    package_dir={'': 'PythonAPI/source'},
    packages=['carla'],
    ext_modules=get_libcarla_extensions(),
    license='MIT License',
    description='Python API for communicating with the CARLA server (external build).',
    long_description=long_description,
    long_description_content_type='text/markdown',
    url='https://github.com/the78mole/carla-simple-client',
    author='Daniel Glaser',
    author_email='the78mole@gmail.com',
    include_package_data=True,
    python_requires='>=3.8',
    install_requires=[
        'numpy>=1.19.0',
        'pillow>=8.0.0',
    ]
)