import { defineConfig } from "vitepress"
export default defineConfig({
    base: "/LibTSMReactive/",
    title: "LibTSMReactive",
    description: "Reactive state framework for World of Warcraft addons",
    ignoreDeadLinks: true,
    themeConfig: {
        nav: [{ text: "Home", link: "/" }],
        sidebar: [{
            items: [
                { text: "Home", link: "/" },
                { text: "Reactive", link: "/Reactive" },
                { text: "UIBindings", link: "/UIBindings" },
                { text: "UIManager", link: "/UIManager" },
                { text: "ReactiveState", link: "/ReactiveState" },
                { text: "ReactiveStateSchema", link: "/ReactiveStateSchema" },
                { text: "ReactiveStream", link: "/ReactiveStream" },
                { text: "ReactivePublisher", link: "/ReactivePublisher" },
                { text: "ReactivePublisherSchema", link: "/ReactivePublisherSchema" },
            ],
        }],
    },
})
