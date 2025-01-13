module.exports = {
  root: true,
  env: {
    es2022: true,
    node: true,
    commonjs: true,
  },
  parserOptions: {
    ecmaVersion: 2022,
    sourceType: "commonjs",
  },
  extends: [
    "eslint:recommended",
    "plugin:prettier/recommended", // Prettier 설정을 통합
  ],
  plugins: ["prettier"],
  rules: {
    "no-unused-vars": "warn",
    "no-undef": "error",
    semi: ["error", "always"],
    quotes: ["error", "double"],
    "no-trailing-spaces": "error",
    "object-curly-spacing": ["error", "always"],
    "comma-dangle": "off",
    "prettier/prettier": "error", // Prettier 규칙 위반 시 오류 발생
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
