-- tasks.lua
local uv = vim.loop
local json = vim.fn.json_decode
local encode = vim.fn.json_encode
local notify = vim.notify
local M = {}

local has_telescope, pickers = pcall(require, "telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local task_file = vim.fn.expand("~/.nvim-tasks/tasks.json")

local function read_tasks()
	local fd = uv.fs_open(task_file, "r", 438)
	if not fd then
		return {}
	end
	local stat = uv.fs_fstat(fd)
	local data = uv.fs_read(fd, stat.size, 0)
	uv.fs_close(fd)
	return json(data) or {}
end

local function write_tasks(tasks)
	uv.fs_mkdir(vim.fn.expand("~/.nvim-tasks"), 493, function() end) -- create dir if needed
	local fd = uv.fs_open(task_file, "w", 438)
	if not fd then
		return
	end
	uv.fs_write(fd, encode(tasks), 0)
	uv.fs_close(fd)
end

local function parse_time_input(input)
	if not input then
		return nil
	end
	local now = os.time()

	if input:match("^%d+[hd]$") then
		local amount, unit = input:match("^(%d+)([hd])$")
		local seconds = unit == "h" and tonumber(amount) * 3600 or tonumber(amount) * 86400
		return os.date("%Y-%m-%d %H:%M", now + seconds)
	end

	if input:match("^today %d%d:%d%d$") then
		local hour, min = input:match("today (%d%d):(%d%d)")
		local today = os.date("*t")
		today.hour = tonumber(hour)
		today.min = tonumber(min)
		today.sec = 0
		return os.date("%Y-%m-%d %H:%M", os.time(today))
	end

	if input:match("^tomorrow %d%d:%d%d$") then
		local hour, min = input:match("tomorrow (%d%d):(%d%d)")
		local t = os.date("*t")
		t.day = t.day + 1
		t.hour = tonumber(hour)
		t.min = tonumber(min)
		t.sec = 0
		return os.date("%Y-%m-%d %H:%M", os.time(t))
	end

	return input
end

function M.add_task(title, time)
	local tasks = read_tasks()
	table.insert(tasks, {
		id = uv.hrtime(),
		title = title,
		completed = false,
		time = time or nil,
	})
	write_tasks(tasks)
	notify("Task added: " .. title)
end

function M.toggle_task(index)
	local tasks = read_tasks()
	if tasks[index] then
		tasks[index].completed = not tasks[index].completed
		write_tasks(tasks)
		notify("Toggled task: " .. tasks[index].title)
	end
end

function M.get_tasks_as_lines()
	local tasks = read_tasks()
	local lines = {}
	for i, task in ipairs(tasks) do
		local checkbox = task.completed and "[x]" or "[ ]"
		table.insert(lines, string.format("%d. %s %s", i, checkbox, task.title))
	end
	return lines
end

function M.check_due_tasks()
	local now = os.time()
	for _, task in ipairs(read_tasks()) do
		if task.time and not task.completed then
			local due = os.time({
				year = tonumber(task.time:sub(1, 4)),
				month = tonumber(task.time:sub(6, 7)),
				day = tonumber(task.time:sub(9, 10)),
				hour = tonumber(task.time:sub(12, 13)),
				min = tonumber(task.time:sub(15, 16)),
				sec = 0,
			})
			if math.abs(now - due) < 60 then -- due within the last minute
				notify("Reminder: " .. task.title, vim.log.levels.INFO, { title = "Task Due" })
			end
		end
	end
end

function M.show_tasks()
	local tasks = read_tasks()
	local entries = {}
	for i, task in ipairs(tasks) do
		local checkbox = task.completed and "[x]" or "[ ]"
		table.insert(entries, string.format("%d. %s %s", i, checkbox, task.title))
	end

	pickers
		.new({}, {
			prompt_title = "Task List",
			finder = finders.new_table({
				results = entries,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(_, map)
				actions.select_default:replace(function(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					local index = tonumber(selection[1]:match("^(%d+)"))
					if index then
						M.toggle_task(index)
					end
				end)
				return true
			end,
		})
		:find()
end

function M.prompt_add_task()
	vim.ui.input({ prompt = "Task title: " }, function(title)
		if not title then
			return
		end
		vim.ui.input({ prompt = "Optional time (e.g. '3h', 'today 10:00'): " }, function(time)
			local parsed_time = parse_time_input(time)
			M.add_task(title, parsed_time)
		end)
	end)
end

-- Commands
if not vim.g.tasks_commands_loaded then
	vim.api.nvim_create_user_command("AddTask", function()
		M.prompt_add_task()
	end, {})

	vim.api.nvim_create_user_command("ShowTasks", function()
		M.show_tasks()
	end, {})
	vim.g.tasks_commands_loaded = true
end

-- Schedule to check every minute
vim.defer_fn(function()
	M.check_due_tasks()
	vim.defer_fn(M.check_due_tasks, 60000) -- every 60 seconds
end, 1000)

return M
