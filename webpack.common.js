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
	resolve: {
		extensions: ["...", ".svelte"],
		mainFields: ["svelte", "browser", "module", "main"],
	},
	devServer: {
		static: { directory: __dirname + "/dist" },
		port: 8000,
	},
	optimization: {
		minimizer: [
			"...",
			new HtmlMinimizerPlugin(),
		],
	},
}
