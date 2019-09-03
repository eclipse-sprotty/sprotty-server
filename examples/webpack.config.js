const path = require('path');
const webpack = require('webpack');

module.exports = {
	mode: 'development',
	devtool: 'source-map',

	entry: {
		circlegraph: './circlegraph/src/main/ts/main.ts'
	},

	output: {
		filename: '[name].js',
		path: path.resolve(__dirname, 'runner/src/main/webapp')
	},

	module: {
		rules: [
			{
				test: /\.(ts|tsx)$/,
				use: ['ts-loader'],
        		exclude: /node_modules/
			},
			{
				test: /\.js$/,
				use: ['source-map-loader'],
				enforce: 'pre'
			},
			{
				test: /\.css$/,
				use: ['style-loader', 'css-loader'],
			}
		]
	},

	resolve: {
		extensions: ['.tsx', '.ts', '.js']
	},

	plugins: [new webpack.ProgressPlugin()]
};
