const CopyPlugin = require("copy-webpack-plugin")
const HtmlMinimizerPlugin = require("html-minimizer-webpack-plugin")

module.exports = {
	entry: {
		index: "./http/index.js",
	},
	output: {
		path: __dirname + "/dist",
		filename: "[name].js",
	},
	module: {
		rules: [
			{
				test: /\.html$/i,
				type: "asset/resource",
			},
			{
				test: /\.(html|svelte)$/i,
				use: "svelte-loader",
			},
		],
	},
	plugins: [
		new CopyPlugin({
			patterns: [
				{
					context: __dirname + "/http",
					from: "*.html",
				},
			],
		}),
	],
	optimization: {
		minimize: true,
		minimizer: [
			new HtmlMinimizerPlugin(),
		],
	},
	resolve: {
		extensions: ["...", ".svelte"],
		mainFields: ["svelte", "browser", "module", "main"],
	},
}
