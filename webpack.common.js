const CopyPlugin = require("copy-webpack-plugin")
const HtmlMinimizerPlugin = require("html-minimizer-webpack-plugin")
const dist = __dirname + "/dist"
const http = __dirname + "/http"

module.exports = {
	entry: {
		index: "./http/index.js",
	},
	output: {
		path: dist,
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
					context: http,
					from: "*.html",
				},
				{
					context: http,
					from: "textures/*/*.jpg",
				},
			],
		}),
	],
	resolve: {
		extensions: ["...", ".svelte"],
		mainFields: ["svelte", "browser", "module", "main"],
	},
	devServer: {
		static: { directory: dist },
		port: 8000,
	},
	optimization: {
		minimizer: [
			"...",
			new HtmlMinimizerPlugin(),
		],
	},
}
