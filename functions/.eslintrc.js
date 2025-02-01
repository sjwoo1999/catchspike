module.exports = {
  root: true,
  env: {
    es2022: true,
    node: true,
    commonjs: true,
  },
  parserOptions: {
    ecmaVersion: "latest",
    sourceType: "module",
  },
  extends: ["eslint:recommended", "plugin:prettier/recommended"],
  plugins: ["prettier"],
  rules: {
    "no-unused-vars": ["warn", { argsIgnorePattern: "^_" }], // `_`로 시작하는 변수 무시
    "no-undef": "error",
    "no-trailing-spaces": "error",
    "no-console": process.env.NODE_ENV === "production" ? "error" : "warn", // 개발 환경에서는 허용, 배포 환경에서는 금지
    "object-curly-spacing": ["error", "always"],
    "comma-dangle": ["error", "always-multiline"], // 멀티라인에서는 항상 쉼표 유지
    semi: ["error", "always"], // 세미콜론 강제
    quotes: ["error", "double"], // 더블 쿼트 강제
    "prettier/prettier": "error",
    strict: ["error", "global"], // use strict 강제 적용
  },
  globals: {
    require: "readonly",
    module: "readonly",
    exports: "readonly",
    process: "readonly",
    __dirname: "readonly",
    __filename: "readonly",
  },
};
