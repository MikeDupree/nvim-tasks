# nvim-tasks

A lightweight task manager plugin for Neovim written in Lua — with Telescope integration, simple due-date reminders, and quick task creation.

## ✨ Features
- `:AddTask`: Add a task with optional time (3h, tomorrow 12:00, etc)
- `:ShowTasks`: View tasks in Telescope UI and toggle them as done
- 🕐 Due tasks show reminders via `vim.notify` when it's time
- 📁 Tasks saved in `~/.nvim-tasks/tasks.json`
- Works with [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## 📦 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "mikedupree/nvim-tasks",
  config = function()
    require("nvim-tasks")
  end,
  dependencies = { "nvim-telescope/telescope.nvim" }
}
```

⏰ Reminders
If a task includes a timestamp like 2025-04-17 16:00, you'll get a popup when it's due (within 60 seconds of your current time).

📂 Storage
Tasks are saved in:

bash
Copy
Edit
~/.nvim-notes/tasks.json
This will be configurable in a future release.

🔜 Coming Soon
Configurable storage location

Recurring tasks

Task tags or project-specific tasks

Calendar integration (maybe 😎)

💌 Contributing
Feel free to open issues or PRs!
