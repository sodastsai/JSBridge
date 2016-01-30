'use strict';

const gulp = require('gulp');
const ts = require('gulp-typescript');

gulp.task('compile-ts', function() {
    const tsProject = ts.createProject('tsconfig.json');
    tsProject.src().pipe(ts(tsProject)).pipe(gulp.dest('.'));
});

gulp.task('watch-ts', function() {
    return gulp.watch(['**/*.ts', '!node_modules/**/*.ts'], ['compile-ts']);
});
