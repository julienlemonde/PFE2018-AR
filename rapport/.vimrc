if has("autocmd")
    autocmd BufWritePost *.tex Dispatch
    autocmd BufWritePost *.bib Dispatch
endif
