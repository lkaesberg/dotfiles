return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          visible = true, -- This makes hidden files visible but slightly dimmed
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
    },
  },
}
