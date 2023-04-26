package trivy

import data.lib.trivy

default ignore = false

ignore_pkgs := {"setuptools"}

ignore {
	input.PkgName == ignore_pkgs[_]
}
