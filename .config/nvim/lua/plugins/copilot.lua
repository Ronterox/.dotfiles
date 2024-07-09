return {
    -- copilot
    {
        "github/copilot.vim",
        event = { "InsertCharPre" },
        cmd = "Copilot",
        build = ":Copilot setup"
    },
}
