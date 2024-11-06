module.exports = {
    root: true,
    env: {
      es2022: true,
      node: true,
      commonjs: true
    },
    parserOptions: {
      ecmaVersion: 2022,
      sourceType: 'commonjs'
    },
    extends: ['eslint:recommended'],
    rules: {
      'no-unused-vars': 'warn',
      'no-undef': 'error',
      'semi': ['error', 'always'],
      'quotes': ['error', 'single'],
      'no-trailing-spaces': 'error',
      'object-curly-spacing': ['error', 'always'],
      'comma-dangle': ['error', 'never']
    },
    globals: {
      'require': 'readonly',
      'module': 'readonly',
      'exports': 'readonly',
      'process': 'readonly',
      '__dirname': 'readonly',
      '__filename': 'readonly'
    }
  };