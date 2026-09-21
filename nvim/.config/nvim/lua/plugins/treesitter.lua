vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/site")

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      -- правильный путь к парсерам
      parser_install_dir = vim.fn.stdpath("data") .. "/site",
      ensure_installed = {
        "javascript",
        "jsx",
        "flow",
        "json",
        "html",
        "css",
        "lua",
        "vim",
        "vimdoc",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
}
