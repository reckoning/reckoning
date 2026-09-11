// The legal pages' text. It lives here rather than in the translation
// bundles because it is prose with a legal meaning, not interface copy: it is
// read and edited as whole documents, and a missing line matters more than a
// missing label.
//
// Lines in [square brackets] are the facts this repository does not hold —
// postal address, hosting provider, register entries. They have to be filled
// in before the pages are of any use.

export interface LegalSection {
  title: string
  paragraphs?: string[]
  list?: string[]
  // Table-ish rows for "what is processed, why, and on what basis".
  rows?: Array<{ term: string; description: string }>
}

export interface LegalDocument {
  title: string
  subtitle?: string
  updated: string
  sections: LegalSection[]
}

const PROVIDER = "Marten Klitzke"
const CONTACT_EMAIL = "info@reckoning.me"
const ADDRESS = "[Straße und Hausnummer], [PLZ] [Ort]"

const de: Record<string, LegalDocument> = {
  impressum: {
    title: "Impressum",
    subtitle: "Angaben gemäß § 5 DDG",
    updated: "Stand: September 2026",
    sections: [
      {
        title: "Diensteanbieter",
        paragraphs: [`${PROVIDER}`, ADDRESS, "Deutschland"],
      },
      {
        title: "Kontakt",
        paragraphs: [`E-Mail: ${CONTACT_EMAIL}`, "Telefon: [Telefonnummer]"],
      },
      {
        title: "Umsatzsteuer-Identifikationsnummer",
        paragraphs: [
          "Umsatzsteuer-Identifikationsnummer gemäß § 27 a Umsatzsteuergesetz: [USt-IdNr.]",
        ],
      },
      {
        title: "Verantwortlich für den Inhalt nach § 18 Abs. 2 MStV",
        paragraphs: [`${PROVIDER}`, ADDRESS],
      },
      {
        title: "Streitbeilegung",
        paragraphs: [
          "Die Europäische Kommission stellt eine Plattform zur Online-Streitbeilegung bereit: https://ec.europa.eu/consumers/odr/",
          "Wir sind nicht bereit und nicht verpflichtet, an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen.",
        ],
      },
      {
        title: "Haftung für Inhalte",
        paragraphs: [
          "Als Diensteanbieter sind wir für eigene Inhalte auf diesen Seiten nach den allgemeinen Gesetzen verantwortlich. Wir sind jedoch nicht verpflichtet, übermittelte oder gespeicherte fremde Informationen zu überwachen oder nach Umständen zu forschen, die auf eine rechtswidrige Tätigkeit hinweisen.",
          "Verpflichtungen zur Entfernung oder Sperrung der Nutzung von Informationen nach den allgemeinen Gesetzen bleiben hiervon unberührt. Eine diesbezügliche Haftung ist jedoch erst ab dem Zeitpunkt der Kenntnis einer konkreten Rechtsverletzung möglich. Bei Bekanntwerden entsprechender Rechtsverletzungen entfernen wir diese Inhalte umgehend.",
        ],
      },
      {
        title: "Haftung für Links",
        paragraphs: [
          "Unser Angebot enthält Links zu externen Websites Dritter, auf deren Inhalte wir keinen Einfluss haben. Deshalb können wir für diese fremden Inhalte auch keine Gewähr übernehmen. Für die Inhalte der verlinkten Seiten ist stets der jeweilige Anbieter oder Betreiber der Seiten verantwortlich.",
          "Eine permanente inhaltliche Kontrolle der verlinkten Seiten ist ohne konkrete Anhaltspunkte einer Rechtsverletzung nicht zumutbar. Bei Bekanntwerden von Rechtsverletzungen entfernen wir derartige Links umgehend.",
        ],
      },
      {
        title: "Urheberrecht",
        paragraphs: [
          "Die durch die Seitenbetreiber erstellten Inhalte und Werke auf diesen Seiten unterliegen dem deutschen Urheberrecht. Die Vervielfältigung, Bearbeitung, Verbreitung und jede Art der Verwertung außerhalb der Grenzen des Urheberrechtes bedürfen der schriftlichen Zustimmung des jeweiligen Autors bzw. Erstellers.",
          "Die Software selbst ist quelloffen und unter https://github.com/reckoning/reckoning einsehbar; für sie gelten die dort angegebenen Lizenzbedingungen.",
        ],
      },
    ],
  },

  privacy: {
    title: "Datenschutzerklärung",
    updated: "Stand: September 2026",
    sections: [
      {
        title: "Verantwortlicher",
        paragraphs: [
          "Verantwortlich für die Verarbeitung personenbezogener Daten auf dieser Website und in dieser Anwendung ist:",
          `${PROVIDER}, ${ADDRESS}, E-Mail: ${CONTACT_EMAIL}`,
        ],
      },
      {
        title: "Überblick",
        paragraphs: [
          "Reckoning ist eine Anwendung zur Zeiterfassung und Rechnungsstellung. Wir verarbeiten die Daten, die Sie uns für Ihren Account geben, und die Daten, die Sie selbst in der Anwendung anlegen — etwa Kunden, Projekte, Zeiten und Rechnungen.",
          "Für die Daten, die Sie über Ihre eigenen Kunden in der Anwendung speichern, sind Sie der Verantwortliche; wir verarbeiten sie in Ihrem Auftrag.",
        ],
      },
      {
        title: "Welche Daten wir verarbeiten",
        rows: [
          {
            term: "Account und Anmeldung",
            description:
              "E-Mail-Adresse, Name, verschlüsseltes Passwort, Zeitpunkt und IP-Adresse der letzten Anmeldungen, optional ein zweiter Faktor. Grundlage: Art. 6 Abs. 1 lit. b DSGVO (Vertrag).",
          },
          {
            term: "Accountdaten",
            description:
              "Firmenname, Anschrift, Steuernummer, Bankverbindung und Kontaktdaten, soweit Sie sie für Ihre Rechnungen hinterlegen. Grundlage: Art. 6 Abs. 1 lit. b DSGVO.",
          },
          {
            term: "Inhalte",
            description:
              "Kunden, Projekte, Aufgaben, erfasste Zeiten, Angebote, Rechnungen, Ausgaben und hochgeladene Belege. Grundlage: Art. 6 Abs. 1 lit. b DSGVO.",
          },
          {
            term: "Server-Logdateien",
            description:
              "Beim Aufruf werden technisch notwendige Daten übertragen und protokolliert: IP-Adresse, Zeitpunkt, angefragte Ressource, Statuscode, Browser und Betriebssystem. Grundlage: Art. 6 Abs. 1 lit. f DSGVO (sicherer Betrieb).",
          },
          {
            term: "Cookies",
            description:
              "Wir setzen ein Sitzungs-Cookie, das Ihre Anmeldung trägt, und — wenn Sie „Angemeldet bleiben“ wählen — ein dauerhaftes Cookie. Beides ist für den Betrieb erforderlich; Tracking- oder Werbe-Cookies setzen wir nicht.",
          },
        ],
      },
      {
        title: "Empfänger und Dienste Dritter",
        paragraphs: [
          "Zur Bereitstellung der Anwendung setzen wir die folgenden Dienste ein. Wo Daten außerhalb der EU verarbeitet werden, geschieht dies auf Grundlage der Standardvertragsklauseln der EU-Kommission.",
        ],
        rows: [
          {
            term: "Hosting",
            description:
              "[Hosting-Anbieter, Anschrift] — Betrieb der Server und Speicherung aller oben genannten Daten. Auftragsverarbeitung nach Art. 28 DSGVO.",
          },
          {
            term: "Dateispeicher",
            description:
              "DigitalOcean (Spaces, Region Frankfurt) — Speicherung hochgeladener Dateien wie Belege und Logos.",
          },
          {
            term: "E-Mail-Versand",
            description:
              "[SMTP-Anbieter, Anschrift] — Versand von Bestätigungs-, Benachrichtigungs- und Rechnungs-E-Mails.",
          },
          {
            term: "AppSignal",
            description:
              "AppSignal B.V., Niederlande — Fehler- und Leistungsüberwachung. Dabei fallen technische Daten zu fehlgeschlagenen Anfragen an, die eine Benutzerkennung enthalten können.",
          },
          {
            term: "Stripe",
            description:
              "Stripe Payments Europe Ltd., Irland — Verwaltung der Tarife und, sofern Sie einen kostenpflichtigen Tarif nutzen, der Zahlungen. Zahlungsdaten geben Sie unmittelbar bei Stripe ein.",
          },
          {
            term: "Gravatar",
            description:
              "Automattic Inc., USA — wenn Sie ein Profilbild über Gravatar nutzen, wird ein Hash Ihrer E-Mail-Adresse an gravatar.com übermittelt, um das Bild abzurufen. Ohne hinterlegte Gravatar-Adresse wird ein automatisch erzeugtes Bild verwendet.",
          },
          {
            term: "Google Fonts und Font Awesome",
            description:
              "Google Ireland Ltd. und Fonticons Inc., USA — Schriftart und Symbole werden beim Seitenaufruf von deren Servern geladen. Dabei wird Ihre IP-Adresse an den jeweiligen Anbieter übertragen. Grundlage: Art. 6 Abs. 1 lit. f DSGVO.",
          },
        ],
      },
      {
        title: "Speicherdauer",
        paragraphs: [
          "Wir speichern Ihre Daten, solange Ihr Account besteht. Nach der Löschung des Accounts werden die Daten gelöscht, soweit keine gesetzlichen Aufbewahrungspflichten entgegenstehen — insbesondere die handels- und steuerrechtlichen Fristen von sechs bzw. zehn Jahren für Rechnungen.",
          "Server-Logdateien werden nach spätestens [Anzahl] Tagen gelöscht.",
        ],
      },
      {
        title: "Ihre Rechte",
        paragraphs: [
          "Sie haben das Recht auf Auskunft (Art. 15 DSGVO), Berichtigung (Art. 16), Löschung (Art. 17), Einschränkung der Verarbeitung (Art. 18), Datenübertragbarkeit (Art. 20) und Widerspruch gegen Verarbeitungen, die auf einem berechtigten Interesse beruhen (Art. 21).",
          `Für alle diese Anliegen genügt eine E-Mail an ${CONTACT_EMAIL}.`,
          "Außerdem haben Sie das Recht, sich bei einer Datenschutz-Aufsichtsbehörde zu beschweren. Zuständig ist die Behörde Ihres Wohnsitzes oder unseres Sitzes.",
        ],
      },
      {
        title: "Datensicherheit",
        paragraphs: [
          "Die Verbindung zur Anwendung ist durchgehend mit TLS verschlüsselt. Passwörter werden ausschließlich als Hash gespeichert; eine Zwei-Faktor-Anmeldung steht zur Verfügung.",
        ],
      },
    ],
  },

  terms: {
    title: "Allgemeine Geschäftsbedingungen",
    updated: "Stand: September 2026",
    sections: [
      {
        title: "1. Geltungsbereich",
        paragraphs: [
          `Diese Bedingungen gelten für die Nutzung der Anwendung Reckoning, bereitgestellt von ${PROVIDER}, ${ADDRESS} (nachfolgend „Anbieter“).`,
          "Abweichende Bedingungen des Kunden werden nicht Vertragsbestandteil, es sei denn, der Anbieter stimmt ihnen ausdrücklich zu.",
        ],
      },
      {
        title: "2. Leistungsgegenstand",
        paragraphs: [
          "Der Anbieter stellt dem Kunden eine webbasierte Anwendung zur Zeiterfassung, Angebots- und Rechnungsstellung zur Nutzung über das Internet bereit. Der Funktionsumfang ergibt sich aus dem jeweils gewählten Tarif.",
          "Der Anbieter entwickelt die Anwendung fortlaufend weiter und kann einzelne Funktionen ändern, sofern der vertragsgemäße Zweck dadurch nicht beeinträchtigt wird.",
        ],
      },
      {
        title: "3. Vertragsschluss und Testphase",
        paragraphs: [
          "Der Vertrag kommt mit der Registrierung und der Bestätigung der E-Mail-Adresse zustande.",
          "Neue Accounts beginnen mit einer kostenlosen Testphase. Nach deren Ablauf bleiben die vorhandenen Daten lesbar; neue Einträge können erst nach Abschluss eines kostenpflichtigen Tarifs angelegt werden.",
        ],
      },
      {
        title: "4. Preise und Zahlung",
        paragraphs: [
          "Es gelten die zum Zeitpunkt der Bestellung auf der Website angegebenen Preise. Alle Preise verstehen sich zuzüglich der gesetzlichen Umsatzsteuer.",
          "Die Vergütung ist im Voraus für den jeweiligen Abrechnungszeitraum fällig.",
        ],
      },
      {
        title: "5. Laufzeit und Kündigung",
        paragraphs: [
          "Der Vertrag läuft auf unbestimmte Zeit und kann von beiden Seiten zum Ende des jeweiligen Abrechnungszeitraums gekündigt werden.",
          "Das Recht zur außerordentlichen Kündigung aus wichtigem Grund bleibt unberührt.",
        ],
      },
      {
        title: "6. Pflichten des Kunden",
        list: [
          "Der Kunde hält seine Zugangsdaten geheim und gibt sie nicht an Dritte weiter.",
          "Der Kunde stellt sicher, dass er die von ihm eingestellten Daten verarbeiten darf, insbesondere Daten seiner eigenen Kunden.",
          "Der Kunde nutzt die Anwendung nicht rechtswidrig und beeinträchtigt ihren Betrieb nicht.",
        ],
      },
      {
        title: "7. Verfügbarkeit",
        paragraphs: [
          "Der Anbieter bemüht sich um eine möglichst unterbrechungsfreie Verfügbarkeit, schuldet diese aber nicht zu einem bestimmten Prozentsatz. Wartungsarbeiten werden nach Möglichkeit angekündigt und in Zeiten geringer Nutzung gelegt.",
        ],
      },
      {
        title: "8. Daten und Sicherung",
        paragraphs: [
          "Der Kunde bleibt Inhaber der von ihm eingestellten Daten. Der Anbieter erstellt regelmäßig Sicherungen; der Kunde ist gehalten, seine Daten zusätzlich selbst zu exportieren.",
          "Nach Vertragsende werden die Daten des Kunden gelöscht, soweit keine gesetzlichen Aufbewahrungspflichten bestehen.",
        ],
      },
      {
        title: "9. Haftung",
        paragraphs: [
          "Der Anbieter haftet unbeschränkt bei Vorsatz und grober Fahrlässigkeit sowie bei Verletzung von Leben, Körper oder Gesundheit.",
          "Bei leicht fahrlässiger Verletzung wesentlicher Vertragspflichten ist die Haftung auf den vertragstypischen, vorhersehbaren Schaden begrenzt. Im Übrigen ist die Haftung ausgeschlossen.",
        ],
      },
      {
        title: "10. Änderung der Bedingungen",
        paragraphs: [
          "Der Anbieter kann diese Bedingungen ändern und teilt Änderungen mindestens sechs Wochen vorher in Textform mit. Widerspricht der Kunde nicht innerhalb dieser Frist, gelten die Änderungen als angenommen; auf diese Folge wird in der Mitteilung hingewiesen.",
        ],
      },
      {
        title: "11. Schlussbestimmungen",
        paragraphs: [
          "Es gilt das Recht der Bundesrepublik Deutschland unter Ausschluss des UN-Kaufrechts.",
          "Ist der Kunde Kaufmann, ist Gerichtsstand der Sitz des Anbieters.",
          "Sollte eine Bestimmung unwirksam sein, bleibt der Vertrag im Übrigen wirksam.",
        ],
      },
    ],
  },
}

const en: Record<string, LegalDocument> = {
  impressum: {
    title: "Legal notice",
    subtitle: "Information pursuant to § 5 DDG",
    updated: "Last updated: September 2026",
    sections: [
      {
        title: "Provider",
        paragraphs: [`${PROVIDER}`, ADDRESS, "Germany"],
      },
      {
        title: "Contact",
        paragraphs: [`Email: ${CONTACT_EMAIL}`, "Phone: [phone number]"],
      },
      {
        title: "VAT identification number",
        paragraphs: ["VAT ID pursuant to § 27 a of the German VAT Act: [VAT ID]"],
      },
      {
        title: "Responsible for the content pursuant to § 18 (2) MStV",
        paragraphs: [`${PROVIDER}`, ADDRESS],
      },
      {
        title: "Dispute resolution",
        paragraphs: [
          "The European Commission provides a platform for online dispute resolution: https://ec.europa.eu/consumers/odr/",
          "We are neither willing nor obliged to take part in dispute resolution proceedings before a consumer arbitration board.",
        ],
      },
      {
        title: "Liability for content",
        paragraphs: [
          "As a service provider we are responsible for our own content on these pages under general law. We are not obliged, however, to monitor transmitted or stored third-party information or to investigate circumstances that indicate unlawful activity.",
          "Obligations to remove or block the use of information under general law remain unaffected. Liability in this respect is only possible from the point in time at which we become aware of a specific infringement. We remove such content immediately once we learn of it.",
        ],
      },
      {
        title: "Liability for links",
        paragraphs: [
          "Our offering contains links to external websites over whose content we have no influence. We therefore cannot accept any responsibility for that third-party content. The respective provider or operator of the linked pages is always responsible for their content.",
          "Permanent monitoring of the linked pages is not reasonable without concrete evidence of an infringement. We remove such links immediately once we learn of an infringement.",
        ],
      },
      {
        title: "Copyright",
        paragraphs: [
          "The content and works created by the site operators on these pages are subject to German copyright law. Reproduction, adaptation, distribution and any kind of exploitation beyond the limits of copyright require the written consent of the respective author or creator.",
          "The software itself is open source and available at https://github.com/reckoning/reckoning under the licence stated there.",
        ],
      },
    ],
  },

  privacy: {
    title: "Privacy policy",
    updated: "Last updated: September 2026",
    sections: [
      {
        title: "Controller",
        paragraphs: [
          "The controller for the processing of personal data on this website and in this application is:",
          `${PROVIDER}, ${ADDRESS}, email: ${CONTACT_EMAIL}`,
        ],
      },
      {
        title: "Overview",
        paragraphs: [
          "Reckoning is an application for time tracking and invoicing. We process the data you give us for your account, and the data you create in the application yourself — customers, projects, hours and invoices.",
          "For the data you store about your own customers, you are the controller; we process it on your behalf.",
        ],
      },
      {
        title: "What we process",
        rows: [
          {
            term: "Account and sign-in",
            description:
              "Email address, name, encrypted password, time and IP address of recent sign-ins, and optionally a second factor. Basis: Art. 6 (1) (b) GDPR (contract).",
          },
          {
            term: "Account details",
            description:
              "Company name, address, tax number, bank details and contact data, as far as you store them for your invoices. Basis: Art. 6 (1) (b) GDPR.",
          },
          {
            term: "Content",
            description:
              "Customers, projects, tasks, tracked hours, offers, invoices, expenses and uploaded receipts. Basis: Art. 6 (1) (b) GDPR.",
          },
          {
            term: "Server logs",
            description:
              "Every request transmits technically necessary data which is logged: IP address, time, requested resource, status code, browser and operating system. Basis: Art. 6 (1) (f) GDPR (secure operation).",
          },
          {
            term: "Cookies",
            description:
              "We set a session cookie carrying your sign-in and, if you choose “stay signed in”, a persistent one. Both are necessary for operation; we set no tracking or advertising cookies.",
          },
        ],
      },
      {
        title: "Recipients and third-party services",
        paragraphs: [
          "We use the following services to run the application. Where data is processed outside the EU, this is based on the European Commission's standard contractual clauses.",
        ],
        rows: [
          {
            term: "Hosting",
            description:
              "[hosting provider, address] — operation of the servers and storage of all data named above. Processing agreement pursuant to Art. 28 GDPR.",
          },
          {
            term: "File storage",
            description:
              "DigitalOcean (Spaces, Frankfurt region) — storage of uploaded files such as receipts and logos.",
          },
          {
            term: "Email delivery",
            description:
              "[SMTP provider, address] — delivery of confirmation, notification and invoice emails.",
          },
          {
            term: "AppSignal",
            description:
              "AppSignal B.V., Netherlands — error and performance monitoring. This produces technical data about failed requests which may contain a user identifier.",
          },
          {
            term: "Stripe",
            description:
              "Stripe Payments Europe Ltd., Ireland — management of the plans and, on a paid plan, of payments. Payment details are entered directly with Stripe.",
          },
          {
            term: "Gravatar",
            description:
              "Automattic Inc., USA — if you use a Gravatar profile picture, a hash of your email address is sent to gravatar.com to fetch the image. Without a Gravatar address, a generated image is used.",
          },
          {
            term: "Google Fonts and Font Awesome",
            description:
              "Google Ireland Ltd. and Fonticons Inc., USA — the typeface and the icons are loaded from their servers when a page is opened, which transmits your IP address to them. Basis: Art. 6 (1) (f) GDPR.",
          },
        ],
      },
      {
        title: "Retention",
        paragraphs: [
          "We keep your data for as long as your account exists. After the account is deleted the data is erased, unless statutory retention periods apply — in particular the six and ten year periods under commercial and tax law for invoices.",
          "Server logs are deleted after [number] days at the latest.",
        ],
      },
      {
        title: "Your rights",
        paragraphs: [
          "You have the right to access (Art. 15 GDPR), rectification (Art. 16), erasure (Art. 17), restriction of processing (Art. 18), data portability (Art. 20), and to object to processing based on a legitimate interest (Art. 21).",
          `An email to ${CONTACT_EMAIL} is enough for any of these.`,
          "You also have the right to lodge a complaint with a data protection supervisory authority — the one where you live or where we are established.",
        ],
      },
      {
        title: "Security",
        paragraphs: [
          "The connection to the application is TLS-encrypted throughout. Passwords are only ever stored as a hash, and two-factor sign-in is available.",
        ],
      },
    ],
  },

  terms: {
    title: "Terms of service",
    updated: "Last updated: September 2026",
    sections: [
      {
        title: "1. Scope",
        paragraphs: [
          `These terms govern the use of the Reckoning application provided by ${PROVIDER}, ${ADDRESS} (the “provider”).`,
          "Deviating terms of the customer do not become part of the contract unless the provider expressly agrees to them.",
        ],
      },
      {
        title: "2. Subject matter",
        paragraphs: [
          "The provider makes a web-based application for time tracking, offers and invoicing available for use over the internet. The functional scope follows from the plan chosen.",
          "The provider develops the application continuously and may change individual features, provided the contractual purpose is not impaired.",
        ],
      },
      {
        title: "3. Conclusion of contract and trial",
        paragraphs: [
          "The contract is concluded upon registration and confirmation of the email address.",
          "New accounts start with a free trial. When it ends the existing data remains readable; new entries can be created once a paid plan is taken out.",
        ],
      },
      {
        title: "4. Prices and payment",
        paragraphs: [
          "The prices stated on the website at the time of the order apply. All prices are exclusive of statutory VAT.",
          "The fee is due in advance for each billing period.",
        ],
      },
      {
        title: "5. Term and termination",
        paragraphs: [
          "The contract runs for an indefinite period and may be terminated by either party at the end of the current billing period.",
          "The right to terminate for good cause remains unaffected.",
        ],
      },
      {
        title: "6. Customer obligations",
        list: [
          "The customer keeps their credentials confidential and does not pass them on.",
          "The customer ensures they are permitted to process the data they enter, in particular data about their own customers.",
          "The customer does not use the application unlawfully and does not interfere with its operation.",
        ],
      },
      {
        title: "7. Availability",
        paragraphs: [
          "The provider aims for uninterrupted availability but does not owe a particular percentage. Maintenance is announced where possible and scheduled at times of low usage.",
        ],
      },
      {
        title: "8. Data and backups",
        paragraphs: [
          "The customer remains the owner of the data they enter. The provider takes regular backups; the customer is expected to export their data themselves as well.",
          "After the contract ends the customer's data is deleted, unless statutory retention obligations apply.",
        ],
      },
      {
        title: "9. Liability",
        paragraphs: [
          "The provider is liable without limitation for intent and gross negligence, and for injury to life, body or health.",
          "For slightly negligent breach of material contractual obligations, liability is limited to the foreseeable damage typical for this type of contract. Liability is otherwise excluded.",
        ],
      },
      {
        title: "10. Changes to these terms",
        paragraphs: [
          "The provider may change these terms and will announce changes in text form at least six weeks in advance. If the customer does not object within that period the changes are deemed accepted; the announcement will point this out.",
        ],
      },
      {
        title: "11. Final provisions",
        paragraphs: [
          "German law applies, excluding the UN Convention on Contracts for the International Sale of Goods.",
          "If the customer is a merchant, the place of jurisdiction is the provider's registered office.",
          "Should a provision be invalid, the remainder of the contract stays in force.",
        ],
      },
    ],
  },
}

// The German text is the one that binds; English is a reading aid.
export function legalDocument(name: string, locale: string): LegalDocument {
  const documents = locale.startsWith("en") ? en : de

  return documents[name] ?? de[name]
}
