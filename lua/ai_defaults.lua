local M = {}

local uv = vim.uv or vim.loop

M.models = {
  plan   = vim.env.NVIM_COPILOT_MODEL_PLAN   or "claude-opus-4.7",
  edit   = vim.env.NVIM_COPILOT_MODEL_EDIT   or "claude-opus-4.7",
  review = vim.env.NVIM_COPILOT_MODEL_REVIEW or "claude-opus-4.7",
  docs   = vim.env.NVIM_COPILOT_MODEL_DOCS   or vim.env.NVIM_COPILOT_MODEL_PLAN or "claude-opus-4.7",
}

-- Explicit candidates first
M.doc_candidates = {
  "CLAUDE.md",
  "README.md",
  "README",
}

-- Broad discovery second
M.doc_globs = {
  "README*",
  "*.md",
  "docs/*.md",
  "docs/**/*.md",
}

-- Safety limits so docs do not explode prompt size
M.max_docs = tonumber(vim.env.NVIM_COPILOT_MAX_DOCS or "8")
M.max_chars_per_file = tonumber(vim.env.NVIM_COPILOT_MAX_DOC_CHARS or "12000")
M.max_total_chars = tonumber(vim.env.NVIM_COPILOT_MAX_TOTAL_DOC_CHARS or "40000")

local function uniq(items)
  local seen = {}
  local out = {}
  for _, item in ipairs(items or {}) do
    if item and item ~= "" and not seen[item] then
      seen[item] = true
      table.insert(out, item)
    end
  end
  return out
end

local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

local function read_file(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or type(lines) ~= "table" then
    return nil
  end
  return table.concat(lines, "\n")
end

local function glob_paths(pattern)
  local ok, results = pcall(vim.fn.glob, pattern, false, true)
  if not ok or type(results) ~= "table" then
    return {}
  end
  return results
end

function M.find_repo_root(start_path)
  local start = start_path or vim.fn.getcwd()

  local git_marker = vim.fs.find(".git", {
    path = start,
    upward = true,
    stop = uv.os_homedir(),
  })[1]

  if git_marker then
    return vim.fs.dirname(git_marker)
  end

  return start
end

function M.to_cwd_relative(path)
  if not path or path == "" then
    return path
  end

  local rel = vim.fn.fnamemodify(path, ":.")
  if rel and rel ~= "" then
    return rel
  end

  return path
end

function M.find_repo_docs(opts)
  opts = opts or {}

  local root = opts.root or M.find_repo_root(opts.start_path)
  local found = {}

  -- First: explicit candidates
  for _, rel in ipairs(M.doc_candidates) do
    local abs = root .. "/" .. rel
    if file_exists(abs) then
      table.insert(found, abs)
    end
  end

  -- Then: wildcard discovery
  for _, rel_pattern in ipairs(M.doc_globs) do
    local abs_pattern = root .. "/" .. rel_pattern
    for _, abs in ipairs(glob_paths(abs_pattern)) do
      if file_exists(abs) then
        table.insert(found, abs)
      end
    end
  end

  local docs = uniq(found)

  if #docs > M.max_docs then
    local trimmed = {}
    for i = 1, M.max_docs do
      trimmed[i] = docs[i]
    end
    docs = trimmed
  end

  return docs
end

function M.build_docs_context(opts)
  opts = opts or {}

  local docs = opts.docs or M.find_repo_docs(opts)
  if not docs or #docs == 0 then
    return ""
  end

  local out = {}
  local total = 0

  table.insert(out, "Project documentation context (include only if relevant):")

  for _, abs in ipairs(docs) do
    local text = read_file(abs)
    if text and text ~= "" then
      if #text > M.max_chars_per_file then
        text = text:sub(1, M.max_chars_per_file) .. "\n...[truncated]"
      end

      local rel = M.to_cwd_relative(abs)
      local block = table.concat({
        "",
        ("--- BEGIN DOC: %s ---"):format(rel),
        text,
        ("--- END DOC: %s ---"):format(rel),
      }, "\n")

      if total + #block > M.max_total_chars then
        table.insert(out, "\n...[additional docs omitted to stay within prompt budget]")
        break
      end

      total = total + #block
      table.insert(out, block)
    end
  end

  return table.concat(out, "\n")
end

function M.compose(opts)
  opts = opts or {}

  local lines = {}

  if opts.model and opts.model ~= "" then
    table.insert(lines, "$" .. opts.model)
  end

  if opts.include_docs then
    local docs_context = M.build_docs_context(opts)
    if docs_context ~= "" then
      table.insert(lines, docs_context)
    end
  end

  if opts.body and opts.body ~= "" then
    table.insert(lines, opts.body)
  end

  return table.concat(lines, "\n\n")
end

function M.prompt_plan()
  return M.compose({
    model = M.models.plan,
    body = table.concat({
      "Produce a concise implementation plan.",
      "Do not edit code yet.",
      "Call out assumptions, impacted files, edge cases, and validation steps.",
    }, "\n"),
  })
end

function M.prompt_edit()
  return M.compose({
    model = M.models.edit,
    body = table.concat({
      "Implement the requested change.",
      "Prefer minimal diffs.",
      "Preserve surrounding style and conventions.",
      "Briefly explain any non-obvious changes.",
    }, "\n"),
  })
end

function M.prompt_review()
  return M.compose({
    model = M.models.review,
    body = table.concat({
      "Review this code or diff.",
      "List correctness issues, edge cases, and maintainability concerns.",
      "Be concise and concrete.",
    }, "\n"),
  })
end

function M.prompt_docs_plan()
  return M.compose({
    model = M.models.docs,
    include_docs = true,
    body = table.concat({
      "Use the documentation context above if it is relevant.",
      "Produce a concise implementation plan.",
      "Do not edit code yet.",
      "If there is no useful documentation context, rely on the current buffer, selection, and explicitly referenced files only.",
    }, "\n"),
  })
end

function M.prompt_docs_edit()
  return M.compose({
    model = M.models.docs,
    include_docs = true,
    body = table.concat({
      "Use the documentation context above if it is relevant.",
      "Implement the requested change with minimal diffs.",
      "Preserve surrounding style and conventions.",
      "If there is no useful documentation context, rely on the current buffer, selection, and explicitly referenced files only.",
    }, "\n"),
  })
end

-- IMPORTANT:
-- Only non-doc prompts are returned here.
-- Docs-aware prompts are invoked lazily from keymaps so startup doesn't scan repos.
function M.prompts()
  return {
    Plan = {
      prompt = M.prompt_plan(),
      system_prompt = "You are a senior engineer. Optimize for correctness, scope control, and safe changes.",
    },

    Edit = {
      prompt = M.prompt_edit(),
      system_prompt = "You are a senior engineer making safe, reviewable edits.",
    },

    Review = {
      prompt = M.prompt_review(),
      system_prompt = "You are a strict reviewer. Prefer concrete findings over generic commentary.",
    },

    Explain = {
      prompt = "Explain what this code does, including any edge cases and risks.",
    },

    Test = {
      prompt = table.concat({
        "Suggest focused validation steps or tests for this change.",
        "Prefer practical test steps over generic advice.",
      }, "\n"),
    },
  }
end

return M
