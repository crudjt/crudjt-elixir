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

use rustler::{Env, Binary, NifResult, Term};

fn get_library_path() -> PathBuf {
    let project_root = Path::new(env!("CARGO_MANIFEST_DIR"));

    // Формуємо шлях до бібліотеки залежно від ОС та архітектури
    let library_subpath = {
        #[cfg(target_os = "linux")]
        {
            if cfg!(target_arch = "x86_64") {
                "native/linux/store_jt_x86_64.so"
            } else if cfg!(target_arch = "aarch64") {
                "native/linux/store_jt_arm64.so"
            } else {
                panic!("Unsupported architecture for Linux");
            }
        }

        #[cfg(target_os = "macos")]
        {
            if cfg!(target_arch = "x86_64") {
                "native/macos/store_jt_x86_64.dylib"
            } else if cfg!(target_arch = "aarch64") {
                "native/macos/store_jt_arm64.dylib"
            } else {
                panic!("Unsupported architecture for macOS");
            }
        }

        #[cfg(target_os = "windows")]
        {
            if cfg!(target_arch = "x86_64") {
                "native/windows/store_jt_x86_64.dll"
            } else if cfg!(target_arch = "aarch64") {
                "native/windows/store_jt_arm64.dll"
            } else {
                panic!("Unsupported architecture for Windows");
            }
        }

        #[cfg(not(any(target_os = "linux", target_os = "macos", target_os = "windows")))]
        {
            panic!("Unsupported OS");
        }
    };

    // Об'єднуємо шлях до проекту з відносним шляхом до бібліотеки
    project_root.join(library_subpath)
}

lazy_static! {
    pub static ref LIB: Library = {
        unsafe { Library::new(get_library_path()).expect("Failed to load library") }
    };
}

fn _encrypted_key(key: *const c_char) -> Result<u32, Box<dyn std::error::Error>> {
    unsafe {
        // let lib = libloading::Library::new("/path/to/liblibrary.so")?;
        let func: libloading::Symbol<unsafe extern fn(*const c_char) -> u32> = LIB.get(b"encrypted_key")?;
        Ok(func(key))
    }
}

fn _create(data: *const u8, len: usize, ttl: i64, silence_read: i32) -> Result<*const c_char, Box<dyn std::error::Error>> {
    unsafe {
        let func: libloading::Symbol<unsafe extern fn(*const u8, usize, i64, i32) -> *const c_char> = LIB.get(b"__create")?;
        Ok(func(data, len, ttl, silence_read))
    }
}

fn _read(token: *const c_char) -> Result<*const c_char, Box<dyn std::error::Error>> {
    unsafe {
        let func: libloading::Symbol<unsafe extern fn(*const c_char) -> *const c_char> = LIB.get(b"__read")?;
        Ok(func(token))
    }
}

fn _update(token: *const c_char, data: *const u8, len: usize, ttl: i64, silence_read: i32) -> Result<*const c_int, Box<dyn std::error::Error>> {
    unsafe {
        let func: libloading::Symbol<unsafe extern fn(*const c_char, *const u8, usize, i64, i32) -> *const c_int> = LIB.get(b"__update")?;
        Ok(func(token, data, len, ttl, silence_read))
    }
}

fn _delete(token: *const c_char) -> Result<*const c_int, Box<dyn std::error::Error>> {
    unsafe {
        // let lib = libloading::Library::new("/path/to/liblibrary.so")?;
        let func: libloading::Symbol<unsafe extern fn(*const c_char) -> *const c_int> = LIB.get(b"__delete")?;
        Ok(func(token))
    }
}

/////////////////////////////////////////////////////

#[rustler::nif]
fn encrypted_key(key: String) {
    let c_key = CString::new(key).expect("Failed to create CString");
    _encrypted_key(c_key.as_ptr()).unwrap();
}

#[rustler::nif]
fn __create(data: Binary, size: usize, ttl: i64, silence_read: i32) -> NifResult<String> {
    let ptr: *const u8 = data.as_slice().as_ptr();
    let token = _create(ptr, size, ttl, silence_read).unwrap();
    let result_str = unsafe { CStr::from_ptr(token).to_string_lossy().into_owned() };

    Ok(result_str)
}

#[rustler::nif]
fn __read(token: String) -> NifResult<String> {
    let c_token = CString::new(token).expect("Failed to create CString");
    let result = _read(c_token.as_ptr()).unwrap();
    let result_str = unsafe { CStr::from_ptr(result).to_string_lossy().into_owned() };

    Ok(result_str)
}

#[rustler::nif]
fn __update(token: String, data: Binary, size: usize, ttl: i64, silence_read: i32) -> NifResult<bool> {
    let c_token = CString::new(token).expect("Failed to create CString");
    let data_ptr: *const u8 = data.as_slice().as_ptr();
    let result: *const c_int = _update(c_token.as_ptr(), data_ptr, size, ttl, silence_read).unwrap();

    let bool: bool = (result as usize == 1);

    Ok(bool)
}

#[rustler::nif]
fn __delete(token: String) -> NifResult<bool> {
    let c_token = CString::new(token).expect("Failed to create CString");
    let result: *const c_int = _delete(c_token.as_ptr()).unwrap();

    let bool: bool = (result as usize == 1);

    Ok(bool)
}

rustler::init!("Elixir.CRUD_JT", [encrypted_key, __create, __read, __update, __delete]);
