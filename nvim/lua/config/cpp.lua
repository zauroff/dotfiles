-- ~/.config/nvim/lua/config/cpp.lua
-- LazyVim: custom C++ build/run commands for the current file.

local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "C++" })
end

local function is_cpp_buffer()
  local ft = vim.bo.filetype
  return ft == "cpp" or ft == "c" -- include c if you want; remove if not
end

local function ensure_saved()
  if vim.bo.modified then
    vim.cmd("write")
  end
end

local function shell_escape(s)
  return vim.fn.shellescape(s)
end

local function path_join(a, b)
  if a:sub(-1) == "/" then
    return a .. b
  end
  return a .. "/" .. b
end

local function get_current_file()
  local file_abs = vim.fn.expand("%:p")
  if file_abs == nil or file_abs == "" then
    return nil, "No file in current buffer."
  end
  if vim.fn.filereadable(file_abs) ~= 1 then
    return nil, "Current buffer is not a readable file."
  end
  return file_abs, nil
end

local function build_paths()
  local dir_abs = vim.fn.expand("%:p:h")
  local name = vim.fn.expand("%:t:r") -- filename without extension
  local build_dir = path_join(dir_abs, "build")
  local out_bin = path_join(build_dir, name)
  return dir_abs, name, build_dir, out_bin
end

local function open_terminal(cmd, cwd)
  -- Open a terminal split at the bottom and run cmd in cwd
  -- Using termopen keeps you in Neovim with live output.
  vim.cmd("botright split")
  vim.cmd("resize 15")
  vim.cmd("terminal")
  local chan = vim.b.terminal_job_id
  if not chan then
    notify("Failed to open terminal.", vim.log.levels.ERROR)
    return
  end
  -- Set working dir for this window/buffer
  if cwd and cwd ~= "" then
    vim.cmd("lcd " .. vim.fn.fnameescape(cwd))
  end
  -- Send the command to the shell running in the terminal
  vim.api.nvim_chan_send(chan, cmd .. "\n")
end

local function ensure_build_dir(build_dir)
  if vim.fn.isdirectory(build_dir) == 1 then
    return true
  end
  local ok = vim.fn.mkdir(build_dir, "p")
  return ok == 1
end

local function default_flags()
  -- Tweak to taste
  return {
    "-std=c++20",
    "-Wall",
    "-Wextra",
    "-Wpedantic",
    "-O2",
  }
end

local function make_build_cmd(file_abs, out_bin, extra_flags)
  local flags = default_flags()
  if extra_flags and #extra_flags > 0 then
    for _, f in ipairs(extra_flags) do
      table.insert(flags, f)
    end
  end

  -- Construct a safe-ish command string (quote paths)
  local parts = {}
  table.insert(parts, "g++")
  for _, f in ipairs(flags) do
    table.insert(parts, f)
  end
  table.insert(parts, shell_escape(file_abs))
  table.insert(parts, "-o")
  table.insert(parts, shell_escape(out_bin))
  return table.concat(parts, " ")
end

function M.cpp_build(opts)
  opts = opts or {}

  if not is_cpp_buffer() then
    notify("Not a C/C++ buffer (filetype=" .. tostring(vim.bo.filetype) .. ").", vim.log.levels.WARN)
  end

  local file_abs, err = get_current_file()
  if not file_abs then
    notify(err, vim.log.levels.ERROR)
    return
  end

  ensure_saved()

  local dir_abs, _, build_dir, out_bin = build_paths()
  if not ensure_build_dir(build_dir) then
    notify("Failed to create build directory: " .. build_dir, vim.log.levels.ERROR)
    return
  end

  local cmd = make_build_cmd(file_abs, out_bin, opts.extra_flags)
  if opts.terminal then
    open_terminal(cmd, dir_abs)
  else
    vim.cmd("!" .. cmd)
  end
end

function M.cpp_run(opts)
  opts = opts or {}

  local file_abs, err = get_current_file()
  if not file_abs then
    notify(err, vim.log.levels.ERROR)
    return
  end

  ensure_saved()

  local dir_abs, _, build_dir, out_bin = build_paths()
  if not ensure_build_dir(build_dir) then
    notify("Failed to create build directory: " .. build_dir, vim.log.levels.ERROR)
    return
  end

  local build_cmd = make_build_cmd(file_abs, out_bin, opts.extra_flags)

  -- Run from the file's directory so relative paths behave naturally
  local run_cmd = shell_escape(out_bin)
  local cmd = build_cmd .. " && " .. run_cmd

  if opts.terminal then
    open_terminal(cmd, dir_abs)
  else
    vim.cmd("!" .. cmd)
  end
end

function M.setup()
  vim.api.nvim_create_user_command("CppBuild", function(params)
    M.cpp_build({
      terminal = true,  -- change to false if you prefer :! output
      extra_flags = {}, -- add flags here or via separate commands below
    })
  end, { desc = "Build current C++ file into ./build/<name>" })

  vim.api.nvim_create_user_command("CppRun", function(params)
    M.cpp_run({
      terminal = true,
      extra_flags = {},
    })
  end, { desc = "Build + run current C++ file (./build/<name>)" })

  -- Optional: debug-flavored commands
  vim.api.nvim_create_user_command("CppBuildDebug", function()
    M.cpp_build({
      terminal = true,
      extra_flags = { "-g", "-O0" },
    })
  end, { desc = "Build current C++ file with debug flags" })

  vim.api.nvim_create_user_command("CppRunDebug", function()
    M.cpp_run({
      terminal = true,
      extra_flags = { "-g", "-O0" },
    })
  end, { desc = "Build + run current C++ file with debug flags" })
end

return M
