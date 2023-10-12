const defaultTheme = require("tailwindcss/defaultTheme");
const colors = require("tailwindcss/colors");

module.exports = {
  content: [
    "./public/*.html",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/frontend/**/*.{js,vue}",
    "./app/views/**/*.{erb,haml,html,slim}",
    "./node_modules/vue-tailwind-datepicker/**/*.js",
    "./node_modules/litepie-datepicker/**/*.js",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          primary: "#428bca",
          primaryDark: "#3071a9",
          grayBackground: "#272B30",
          grayBorder: "#c8c8c8",
        },
        "litepie-primary": colors.sky, // color system for light mode
        "litepie-secondary": colors.gray, // color system for dark mode
        "vtd-primary": colors.sky, // Light mode Datepicker color
        "vtd-secondary": colors.gray, // Dark mode Datepicker color
      },
      fontFamily: {
        sans: ["Inter var", ...defaultTheme.fontFamily.sans],
        hero: ["Orbitron", "Inter var", ...defaultTheme.fontFamily.sans],
      },
      borderWidth: {
        3: "3px",
        5: "5px",
      },
      borderRadius: {
        panel: "1.25rem",
        button: "0.625rem;",
      },
      height: {
        "3px": "3px",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/aspect-ratio"),
    require("@tailwindcss/typography"),
  ],
};
