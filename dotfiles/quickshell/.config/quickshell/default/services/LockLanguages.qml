pragma Singleton
import QtQuick

// Country code -> display label / virtual-keyboard locale lookup table.
// Verbatim port of the SDDM "silent" theme's components/Languages.qml —
// pure data, zero SDDM dependency.
QtObject {
    property var layouts: {
        "ar": { "label": "العربية", "kb_code": "ar_AR" },
        "bg": { "label": "български", "kb_code": "bg_BG" },
        "cz": { "label": "Čeština ", "kb_code": "cs_CZ" },
        "dk": { "label": "Dansk", "kb_code": "da_DK" },
        "de": { "label": "Deutsch", "kb_code": "de_DE" },
        "gr": { "label": "Ελληνικά", "kb_code": "el_GR" },
        "gb": { "label": "British English", "kb_code": "en_GB" },
        "us": { "label": "American English", "kb_code": "en_US" },
        "es": { "label": "Español", "kb_code": "es_ES" },
        "mx": { "label": "Español (México)", "kb_code": "es_MX" },
        "ee": { "label": "Eesti", "kb_code": "et_EE" },
        "fa": { "label": "فارسى", "kb_code": "fa_FA" },
        "fi": { "label": "Suomi", "kb_code": "fi_FI" },
        "ca": { "label": "Français (Canada)", "kb_code": "fr_CA" },
        "fr": { "label": "Français", "kb_code": "fr_FR" },
        "il": { "label": "עברית", "kb_code": "he_IL" },
        "in": { "label": "हिंदी", "kb_code": "hi_IN" },
        "hr": { "label": "Hrvatski ", "kb_code": "hr_HR" },
        "hu": { "label": "Magyar ", "kb_code": "hu_HU" },
        "id": { "label": "Bahasa Indonesia", "kb_code": "id_ID" },
        "it": { "label": "Italiano", "kb_code": "it_IT" },
        "lv": { "label": "latviešu ", "kb_code": "lv_LV" },
        "jp": { "label": "日本語", "kb_code": "ja_JP" },
        "kr": { "label": "한국어", "kb_code": "ko_KR" },
        "my": { "label": "Bahasa Malaysia", "kb_code": "ms_MY" },
        "no": { "label": "Norsk ", "kb_code": "nb_NO" },
        "nl": { "label": "Nederlands", "kb_code": "nl_NL" },
        "pl": { "label": "Polski", "kb_code": "pl_PL" },
        "br": { "label": "Português (Brasil)", "kb_code": "pt_BR" },
        "pt": { "label": "Português (Portugal)", "kb_code": "pt_PT" },
        "ro": { "label": "Română", "kb_code": "ro_RO" },
        "ru": { "label": "Русский", "kb_code": "ru_RU" },
        "sk": { "label": "Slovenčina", "kb_code": "sk_SK" },
        "si": { "label": "Slovenski", "kb_code": "sl_SI" },
        "al": { "label": "Shqip", "kb_code": "sq_AL" },
        "sp": { "label": "Srpski/Српски", "kb_code": "sr_SP" },
        "se": { "label": "Svenska", "kb_code": "sv_SE" },
        "th": { "label": "ไทย", "kb_code": "th_TH" },
        "tr": { "label": "Türkçe", "kb_code": "tr_TR" },
        "ua": { "label": "Українська", "kb_code": "uk_UA" },
        "vn": { "label": "Tiếng Việt", "kb_code": "vi_VN" },
        "cn": { "label": "简体中文", "kb_code": "zh_CN" },
        "tw": { "label": "繁體中文", "kb_code": "zh_TW" }
    }

    function getKBCodeFor(country) {
        return country && layouts[country] ? layouts[country]["kb_code"] : ""
    }

    function getLabelFor(country) {
        return country && layouts[country] ? layouts[country]["label"] : ""
    }
}
