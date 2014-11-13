#!/usr/bin/gawk -f

/ ServerHello / {
	protocols[$5]++;
	ciphers[$7]++;
	pc[$5 "\t" $7]++;
}

function dump(name, counters) {
	print name
	for (c in counters) {
		print counters[c] "\t" c;
	}
}

END {
	PROCINFO["sorted_in"]="@val_num_desc"; # gawk-specific array sorting
	dump("Protocols:", protocols);
	dump("\nCiphers:", ciphers);
	dump("\nProtocols+Ciphers:", pc);
}
