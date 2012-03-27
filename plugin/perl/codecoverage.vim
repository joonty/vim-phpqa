"
" Description:
" Add code coverage signs to file
"
if has("perl")
perl <<EOF
sub AddCodeCoverageSigns {
	my $clover = shift;
	local $line;
	local $file;
	local $bufname;

	(undef, $bufname) = VIM::Eval("bufname(\"%\")");
	(undef, $file) = VIM::Eval("fnamemodify('$bufname', ':p')");

	use XML::XPath;
	use XML::XPath::XMLParser;

	#VIM::DoCommand("echohl Error| echo \"$file\"|echohl None");
	eval {
		my $xp = XML::XPath->new(filename => $clover);

		my $nodeset = $xp->find('/coverage/project/file[@name="'.$file.'"]/line[@type="stmt"]'); # find all paragraphs

		foreach my $node ($nodeset->get_nodelist) {
			my $line = $node->getAttribute("num");
			my $count = $node->getAttribute("count");
			my $sign = $count > 0 ?  "CodeCoverageNotCovered" : "CodeCoverageCovered";
			VIM::DoCommand("let s:num_cc_signs = s:num_cc_signs + 1");
			VIM::DoCommand("sign place 4783 name=$sign line=$line file=$file");
		}
	} or do {
		VIM::DoCommand("echohl Error| echo \"Failed to read clover XML file $clover: $@\"|echohl None");
		VIM::DoCommand('let g:phpqa_codecoverage_file = ""');
	};
}
EOF
endif
