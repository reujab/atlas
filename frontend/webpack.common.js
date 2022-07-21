const CopyPlugin = require("copy-webpack-plugin")
const HtmlMinimizerPlugin = require("html-minimizer-webpack-plugin")
const dist = __dirname + "/http"
const src = __dirname + "/src"

module.exports = {
	target: "electron-renderer",
	entry: {
		index: "./src/index.js",
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
					context: src,
					from: "*.html",
				},
				{
					context: src,
					from: "backgrounds/*/*.webp",
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
		hot: false,
		liveReload: false,
		magicHtml: false,
	},
	devtool: "source-map",
	optimization: {
		minimizer: [
			"...",
			new HtmlMinimizerPlugin({
				minimizerOptions: {
					collapseBooleanAttributes: true,
					collapseInlineTagWhitespace: true,
					conservativeCollapse: false,
					keepClosingSlash: false,
				},
			}),
		],
	},
}
