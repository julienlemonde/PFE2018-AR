if has("autocmd")
    autocmd BufWritePost *.tex Dispatch
    autocmd BufWritePost *.bib Dispatch
    autocmd BufWritePost *.puml Dispatch! plantuml %
endif
