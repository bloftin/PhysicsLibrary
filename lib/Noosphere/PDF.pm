package Noosphere;

use strict;
use Encode qw(encode decode FB_CROAK);
use Text::Balanced qw(extract_bracketed);
require Noosphere::Charset;

# Profile fields are plain text, not executable TeX. Emit UTF-8 bytes to match
# the existing raw .tex writer, using the site's accent mappings where possible.
sub pdfText {
	my $text = shift // '';
	unless (utf8::is_utf8($text)) {
		my $decoded = eval { decode('UTF-8', $text, FB_CROAK) };
		$text = defined($decoded) ? $decoded : decode('ISO-8859-1', $text);
	}
	my %escape = (
		'\\' => '\textbackslash{}', '{' => '\{', '}' => '\}',
		'$' => '\$', '&' => '\&', '%' => '\%', '#' => '\#',
		'_' => '\_', '^' => '\textasciicircum{}', '~' => '\textasciitilde{}',
	);
	$text =~ s/([\\{}\$&%#_^~])/$escape{$1}/ge;
	$text =~ s/[\r\n\t]+/ /g;
	return encode('UTF-8', UTF8toTeX(encode('UTF-8', $text)));
}

sub pdfTitle {
	my $title = shift // '';
	# Keep the math convention used by titles elsewhere on the site.
	return join('', map { /^\$/ ? $_ : pdfText(TeXtoUTF8($_)) }
		split(/(\$[^\$]+\$)/, $title));
}

sub pdfDocumentPresentation {
	my ($latex, $meta) = @_;
	return $latex unless $latex =~ /^[ \t]*\\begin\s*\{document\}/m;
	my ($start, $body_start) = ($-[0], $+[0]);
	my $end;
	while ($latex =~ /^[ \t]*\\end\s*\{document\}/mg) { $end = $-[0]; }
	return $latex unless defined($end) && $end > $body_start;
	my $preamble = substr($latex, 0, $start);
	my $body = substr($latex, $body_start, $end - $body_start);
	my $ending = substr($latex, $end);

	my $title = $meta->{title} // '';
	# Entries commonly repeat their metadata title in an initial section*.
	# Balanced parsing preserves nested braces in mathematical titles.
	if ($body =~ /\A(?:\s|%[^\n]*\n)*\\section\*\s*(?=\{)/) {
		my $offset = $+[0];
		my ($heading) = extract_bracketed(substr($body, $offset), '{}');
		if (defined($heading) && length($heading)) {
			my $heading_title = substr($heading, 1, -1);
			my $plain_title = $title;
			for ($heading_title, $plain_title) { s/\s+/ /g; s/^\s+|\s+$//g; }
			substr($body, 0, $offset + length($heading), '') if $heading_title eq $plain_title;
		}
	}

	my $owner = $meta->{owner} || {};
	# Active profiles publish these fields; inactive profiles hide personal data.
	my $name = $owner->{active} ? join(' ', grep { defined($_) && /\S/ }
		$owner->{forename}, $owner->{surname}) : '';
	my $byline = length($name) ? '{\small Maintained by ' . pdfText($name) . "\\par}\n" : '';
	my $brand = '{\Large\bfseries PhysicsLibrary.org\par}';
	if (defined($meta->{logo}) && -r $meta->{logo} && $meta->{logo} !~ /[{}%\r\n]/) {
		$brand = '\includegraphics[width=2.5in,height=0.45in,keepaspectratio]{\detokenize{'
			. $meta->{logo} . '}}\par';
	}
	my $header = "\n% PhysicsLibrary PDF presentation\n"
		. "\\pagestyle{plpdf}\\thispagestyle{plpdf}\n"
		. "{\\parindent=0pt\n{\\parskip=0pt\n$brand\n"
		. "{\\small\\itshape An open source physics library\\par}\n}\n\\medskip\n";
	# Full collaboration documents may have their own title/author machinery.
	if ($body =~ /\A(?:\s|%[^\n]*\n)*\\maketitle\b/) {
		$header .= "}\n";
		$body =~ s/(\\maketitle\b)/$1\n$byline/;
	} else {
		$header .= '{\Large\bfseries ' . pdfTitle($title) . "\\par}\n"
			. $byline . "\\smallskip\\hrule\\medskip\n}\n";
	}

	my @details;
	push @details, 'Version ' . $meta->{version} if ($meta->{version} // '') =~ /^\d+$/;
	my $date = $meta->{modified} || $meta->{created} || '';
	push @details, "Updated $1" if $date =~ /^(\d{4}-\d{2}-\d{2})/;
	if (!length($name) && ($meta->{userid} // '') =~ /^\d+$/ && $meta->{userid} > 0) {
		my $account = $owner->{username} // '';
		push @details, 'Maintained by ' . (length($account) ? pdfText($account) . ' ' : '')
			. '(user ' . $meta->{userid} . ')';
	}
	my $url = $meta->{url} // '';
	$url =~ s/([%#{}])/\\$1/g;
	my $footer = "\n\\par\\addvspace{1.5\\baselineskip}\n"
		. "\\noindent\\begin{minipage}{\\linewidth}\n\\small\\raggedright\n"
		. "\\hrule\\smallskip\nSource: \\url{$url}\\par\n"
		. join(' \quad ', @details) . "\n\\end{minipage}\\par\n";
	my @authors;
	my %seen;
	for my $author (@{$meta->{authors} || []}) {
		my $id = $author->{userid};
		next unless defined($id) && $id =~ /^\d+$/ && $id > 0;
		next if $seen{$id}++;
		my $username = $author->{username} // '';
		push @authors, (length($username) ? pdfText($username) . ' ' : '') . "(user $id)";
	}
	my $authors = @authors ? join('; ', @authors) : 'No author history is recorded; see the source article.';
	my $license_url = $meta->{license_url} || 'https://physicslibrary.org/?op=license';
	$license_url =~ s/([%#{}])/\\$1/g;
	# Keep the source block together, but allow long contributor lists to paginate.
	$footer .= "{\\small\\raggedright\\parskip=3pt\\parindent=0pt\n"
		. "\\medskip\\noindent\\textbf{Article authors:} $authors\\par\n"
		. "\\smallskip\\noindent\\textbf{Copyright and license}\\par\\nobreak\n"
		. "This article is copyrighted by its respective authors. "
		. "Permission is granted to copy, distribute and/or modify this document "
		. "under the terms of the "
		. '\href{https://creativecommons.org/licenses/by-sa/4.0/}{Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0) License}.'
		. "\\par\nLicense notice: \\url{$license_url}\\par\n}\n";
	my $support = <<'TEX';
% PhysicsLibrary PDF support; do not reload author packages with new options.
\makeatletter
\@ifpackageloaded{graphicx}{}{\RequirePackage{graphicx}}
\@ifpackageloaded{hyperref}{}{\RequirePackage{hyperref}}
\def\ps@plpdf{%
  \let\@oddhead\@empty\let\@evenhead\@empty
  \def\@oddfoot{\hfil\normalfont\small\thepage\hfil}%
  \let\@evenfoot\@oddfoot}
\makeatother
TEX
	return $preamble . $support . "\\begin{document}\n" . $header . $body . $footer . $ending;
}

1;
