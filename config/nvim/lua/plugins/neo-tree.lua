return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true,           -- 显示被过滤的项目（不是真的不过滤，只是显示出来变灰）
        hide_dotfiles = false,    -- 不隐藏 . 开头的文件
        hide_gitignored = false,  -- 不隐藏 gitignore 里的文件
        hide_hidden = false,      -- Windows 专用，隐藏带 hidden 属性的
        hide_by_name = {
          -- "node_modules",
          -- ".DS_Store",
        },
        never_show = {            -- 永远不显示（即使 visible = true 也不显示）
          ".DS_Store",
          "thumbs.db",
        },
      },
    },
  },
}
