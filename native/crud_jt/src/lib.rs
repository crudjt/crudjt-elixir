use std::ffi::CString;
use core::ffi::CStr;
use std::os::raw::{c_char, c_int};
use std::ptr;

///
use libloading::{Library, Symbol};
use std::sync::{Mutex, Once};
use lazy_static::lazy_static;
use std::sync::Arc;

use std::path::{Path, PathBuf};

use rustler::{Env, Binary, NifResult, Term, Error};

fn get_library_path() -> Result<PathBuf, String> {
    let project_root = Path::new(env!("CARGO_MANIFEST_DIR"));

    let library_subpath = {
        #[cfg(target_os = "linux")]
        {
            if cfg!(target_arch = "x86_64") {
                "native/linux/store_jt_x86_64.so"
            } else if cfg!(target_arch = "aarch64") {
                "native/linux/store_jt_arm64.so"
            } else {
                return Err("Unsupported architecture for Linux".to_string());
            }
        }

        #[cfg(target_os = "macos")]
        {
            if cfg!(target_arch = "x86_64") {
                "native/macos/store_jt_x86_64.dylib"
            } else if cfg!(target_arch = "aarch64") {
                "native/macos/store_jt_arm64.dylib"
            } else {
                return Err("Unsupported architecture for macOS".to_string());
            }
        }

        #[cfg(target_os = "windows")]
        {
            if cfg!(target_arch = "x86_64") {
                "native/windows/store_jt_x86_64.dll"
            } else if cfg!(target_arch = "aarch64") {
                "native/windows/store_jt_arm64.dll"
            } else {
                return Err("Unsupported architecture for Windows".to_string());
            }
        }

        #[cfg(not(any(target_os = "linux", target_os = "macos", target_os = "windows")))]
        {
            return Err("Unsupported OS".to_string());
        }
    };

    Ok(project_root.join(library_subpath))
}

lazy_static! {
    pub static ref LIB: Result<Library, String> = unsafe {
        get_library_path().and_then(|path| {
            Library::new(path)
                .map_err(|e| format!("Failed to load library: {}", e))
        })
    };
}

fn _start_store_jt(key: *const c_char, path: *const c_char) -> Result<*const c_char, Box<dyn std::error::Error>> {
    let lib = match &*LIB {
        Ok(lib) => lib,
        Err(e) => return Err(e.clone().into())
    };

    unsafe {
        let func: libloading::Symbol<unsafe extern fn(*const c_char, *const c_char) -> *const c_char> = lib.get(b"start_store_jt")?;
        Ok(func(key, path))
    }
}

fn _create(data: *const u8, len: usize, ttl: i64, silence_read: i32) -> Result<*const c_char, Box<dyn std::error::Error>> {
    let lib = match &*LIB {
        Ok(lib) => lib,
        Err(e) => return Err(e.clone().into())
    };

    unsafe {
        let func: libloading::Symbol<unsafe extern fn(*const u8, usize, i64, i32) -> *const c_char> = lib.get(b"__create")?;
        Ok(func(data, len, ttl, silence_read))
    }
}

fn _read(token: *const c_char) -> Result<*const c_char, Box<dyn std::error::Error>> {
    let lib = match &*LIB {
        Ok(lib) => lib,
        Err(e) => return Err(e.clone().into())
    };

    unsafe {
        let func: libloading::Symbol<unsafe extern fn(*const c_char) -> *const c_char> = lib.get(b"__read")?;
        Ok(func(token))
    }
}

fn _update(token: *const c_char, data: *const u8, len: usize, ttl: i64, silence_read: i32) -> Result<*const c_int, Box<dyn std::error::Error>> {
    let lib = match &*LIB {
        Ok(lib) => lib,
        Err(e) => return Err(e.clone().into())
    };

    unsafe {
        let func: libloading::Symbol<unsafe extern fn(*const c_char, *const u8, usize, i64, i32) -> *const c_int> = lib.get(b"__update")?;
        Ok(func(token, data, len, ttl, silence_read))
    }
}

fn _delete(token: *const c_char) -> Result<*const c_int, Box<dyn std::error::Error>> {
    let lib = match &*LIB {
        Ok(lib) => lib,
        Err(e) => return Err(e.clone().into())
    };

    unsafe {
        let func: libloading::Symbol<unsafe extern fn(*const c_char) -> *const c_int> = lib.get(b"__delete")?;
        Ok(func(token))
    }
}

/////////////////////////////////////////////////////

#[rustler::nif]
fn start_store_jt_config(key: String, path: Option<String>) -> NifResult<String> {
    let c_key = CString::new(key).map_err(|_| rustler::Error::RaiseAtom("Failed to create CString"))?;
    let c_path = match path {
        Some(p) => Some(CString::new(p).map_err(|_| rustler::Error::RaiseAtom("Failed to create CString"))?),
        None => None,
    };

    let c_path_ptr = c_path
        .as_ref()
        .map(|s| s.as_ptr());

    let c_path_ptr = match c_path_ptr {
        Some(path) => path,
        None => std::ptr::null()
    };

    let result_ptr: *const i8 = _start_store_jt(c_key.as_ptr(), c_path_ptr)
        .map_err(|_| Error::RaiseAtom("_start_store_jt failed"))?;

    let result_str = unsafe { CStr::from_ptr(result_ptr) }
        .to_string_lossy()
        .into_owned();


    Ok(result_str)
}

#[rustler::nif]
fn __create(data: Binary, size: usize, ttl: i64, silence_read: i32) -> NifResult<String> {
    let ptr: *const u8 = data.as_slice().as_ptr();
    let token = _create(ptr, size, ttl, silence_read).map_err(|_| rustler::Error::RaiseAtom("_create failed"))?;
    let result_str = unsafe { CStr::from_ptr(token).to_string_lossy().into_owned() };

    Ok(result_str)
}

#[rustler::nif]
fn __read(token: String) -> NifResult<Option<String>> {
    let c_token = CString::new(token).map_err(|_| rustler::Error::RaiseAtom("Failed to create CString"))?;
    let result = _read(c_token.as_ptr()).map_err(|_| rustler::Error::RaiseAtom("_read failed"))?;

    if result.is_null() {
        Ok(None)
    } else {
        let result_str = unsafe { CStr::from_ptr(result).to_string_lossy().into_owned() };
        Ok(Some(result_str))
    }
}

#[rustler::nif]
fn __update(token: String, data: Binary, size: usize, ttl: i64, silence_read: i32) -> NifResult<bool> {
    let c_token = CString::new(token).map_err(|_| rustler::Error::RaiseAtom("Failed to create CString"))?;
    let data_ptr: *const u8 = data.as_slice().as_ptr();
    let result: *const c_int = _update(c_token.as_ptr(), data_ptr, size, ttl, silence_read).map_err(|_| rustler::Error::RaiseAtom("_update failed"))?;

    let bool: bool = (result as usize == 1);

    Ok(bool)
}

#[rustler::nif]
fn __delete(token: String) -> NifResult<bool> {
    let c_token = CString::new(token).map_err(|_| rustler::Error::RaiseAtom("Failed to create CString"))?;
    let result: *const c_int = _delete(c_token.as_ptr()).map_err(|_| rustler::Error::RaiseAtom("_delete failed"))?;

    let bool: bool = (result as usize == 1);

    Ok(bool)
}

rustler::init!("Elixir.CRUD_JT", [start_store_jt_config, __create, __read, __update, __delete]);
