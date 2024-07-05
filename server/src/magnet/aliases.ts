// export default {
// 	"Special Victims Unit": "SVU",
// } as { [key: string | RegExp]: string };

export default [
	{ regex: /Special Victims Unit/, replace: "SVU", add: true },
	{ regex: /^House$/, replace: "House MD" },
]
