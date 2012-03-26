"
" Description:
" Perl version of ParseClist for speed.
"
if has("perl")
perl <<EOF
sub ParseClist {
    our %error_hash = ();
    my $sign = shift;
    my $clist;
    my @clist;

    # VIM::Msg("sign: $sign");

    (undef, $clist) = VIM::Eval("s:clist");
    @clist = split /\n/, $clist;

    foreach (@clist) {
        # VIM::Msg("elem: $_\n");

        ($file, $line, $text) = split /:/, $_, 3;

        next if not defined $file;
        next if not defined $line;
        next if not defined $text;
        next if "" eq $file;
        next if "" eq $line;
        next if "" eq $text;

        $file =~ s/\s*\d*\s*//;
        (undef, $file) = VIM::Eval("fnamemodify('$file', ':p')");

        # if fnamemodify was passed an empty string (after clist number was removed)
        next if -d $file;

        # if column information is given in the compiler 
        $line =~ s/(\d*).*/$1/;

        if ("QuickHighGrep" ne $sign) {
            $text = quotemeta $text;
            (undef, $sign) = VIM::Eval("s:GetSign(\"$text\")");
        }

        # VIM::Msg("sign: $sign\nfile: $file\nline: $line\ntext: $text\n");

        $error_hash{$sign}{$file}{$line} = 1;
    } continue {
        # VIM::Msg(" \n");
    }

    if (%error_hash) {
        VIM::DoCommand('let s:error_list = "perl"');
    }
}
EOF
endif

"
" Description:
" Perl version of AddSignsActual for speed.
"
if has("perl")
perl << EOF
sub PlaceSign {
    # VIM::Msg("sign place 4782 name=$sign line=$line file=$file");
    VIM::DoCommand("sign place 4782 name=$sign line=$line file=$file");
    VIM::DoCommand("let s:num_signs = s:num_signs + 1");
    VIM::Eval("setbufvar(\"$bufname\", \"quickhigh_plugin_processed\", 1)");
}

sub AddSignsActual {
    our %error_hash;
    my $which = shift;
    local $sign = shift;
    local $line;
    local $file;
    local $bufname;

    if ("all" eq $which) {
        (undef, $last_buffer) = VIM::Eval("bufnr(\"\$\")");
        foreach $buf (1 .. $last_buffer) {
            (undef, $bufname) = VIM::Eval("bufname($buf)");
            (undef, $file) = VIM::Eval("fnamemodify('$bufname', ':p')");

            foreach $line (keys %{$error_hash{$sign}{$file}}) {
                PlaceSign();
            }
        } # end loop over buffers

    } else {
        (undef, $bufname) = VIM::Eval("bufname(\"%\")");
        (undef, $file) = VIM::Eval("fnamemodify('$bufname', ':p')");

        foreach $line (keys %{$error_hash{$sign}{$file}}) {
            PlaceSign();
        }
    }
}
EOF
endif

" vim: ft=vim ts=4 sw=4 et sts=4
