__formats = {

	"msg": "\033[1mMessage:\033[0m {text}",
	"err": "\033[91mError:\033[0m {text}",
	"wrn": "\033[91mWarning:\033[0m {text}",
	"exc": "\033[93mExeclog:\033[0m {text}",
	"suc": "\033[92mSuccess:\033[0m {text}",
	"nof": "{text}"

}

class NotALogLevel(Exception):
	pass

def log(text: str, level: str = "msg"):

	if level in __formats:
		print(__formats[level].format(text = text))
	else:
		raise NotALogLevel("Invalid log level")