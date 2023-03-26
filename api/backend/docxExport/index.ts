import * as fs from "fs";
import {Document, HeadingLevel, ISectionOptions, Packer, Paragraph, SectionType} from "docx";
import {generateText} from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'

interface InputData {
    studentName: string
    entries: Entry[]
}

interface Entry {
    id: string
    createdAt: string
    createdBy: string
    date: string
    tags: string[]
    events: string[]
    competences: { [key: string]: number }
    description: string
}

interface EntryCompetence {
    name: string
    level: number
}

function writeDocument(data: InputData, out: string) {
    const doc = new Document({
        styles: {
            paragraphStyles: [
                {
                    id: 'normal',
                    name: "Normal",
                    run: {
                        font: "Arial",
                        size: '12pt',
                        color: "#000000"
                    }
                },
                {
                    id: 'ListParagraph',
                    name: "List Paragraph",
                    basedOn: 'normal',
                    quickFormat: true,
                },
                {
                    id: HeadingLevel.HEADING_1,
                    name: "Heading 1",
                    basedOn: 'normal',
                    quickFormat: true,
                    run: {
                        size: '20pt',
                    }
                },
                {
                    id: HeadingLevel.HEADING_2,
                    name: "Heading 2",
                    basedOn: HeadingLevel.HEADING_1,
                    run: {
                        size: '16pt'
                    }
                },
                {
                    id: HeadingLevel.HEADING_3,
                    name: "Heading 3",
                    basedOn: HeadingLevel.HEADING_1,
                    run: {
                        size: '14pt',
                        color: "#434343"
                    }
                }

            ]
        },
        sections: [{
            children: [
                new Paragraph({
                    heading: HeadingLevel.HEADING_1,
                    text: data.studentName
                }),
            ],
        },
            ...data.entries.map(transformEntry)
        ],
    });

    Packer.toBuffer(doc).then((buffer) => {
        fs.writeFileSync(out, buffer);
    });
}

function transformEntry(data: Entry) {
    return {
        properties: {
            type: SectionType.CONTINUOUS,
        },
        children: [
            new Paragraph({
                heading: HeadingLevel.HEADING_2,
                text: formatDate(data.date)
            }),
            new Paragraph({
                text: generateText(JSON.parse(data.description), [StarterKit])
            }),
            new Paragraph({}),
            new Paragraph({
                text: `Erstellt am ${formatDate(data.createdAt)} von ${data.createdBy}`
            }),
            ...transformTags(data),
            ...transformEvents(data),
            ...transformCompetences(data),
            new Paragraph({}),
        ]
    } as ISectionOptions
}

function transformTags(data: Entry) {
    if (!data.tags || data.tags.length === 0) {
        return []
    }

    return [
        new Paragraph({}),
        new Paragraph({
            heading: HeadingLevel.HEADING_3,
            text: "Tags"
        }), ...data.tags.map(tag =>
            new Paragraph({
                bullet: {level: 0},
                text: "#" + tag
            })
        )
    ]
}

function transformEvents(data: Entry) {
    if (!data.events || data.events.length === 0) {
        return []
    }

    return [
        new Paragraph({}),
        new Paragraph({
            heading: HeadingLevel.HEADING_3,
            text: "Events"
        }),
        ...data.events.map(event =>
        new Paragraph({
            bullet: {level: 0},
            text: event,
        }))
    ]
}

function transformCompetences(data: Entry) {
    if (!data.competences || Object.keys(data.competences).length === 0) {
        return []
    }

    const out = [
        new Paragraph({}),
        new Paragraph({
            heading: HeadingLevel.HEADING_3,
            text: "Kompetenzen"
        })
    ]
    for (let competence in data.competences) {
        let level = ''
        if (data.competences[competence] !== -1) {
            level = `: ${data.competences[competence]}/3`
        }

        out.push(new Paragraph({
            bullet: {level: 0},
            text: `${competence}${level}`,
        }))
    }

    return out
}

const months = ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"]

function formatDate(dateString: string) {
    const date = new Date(dateString)
    const month = months[date.getMonth()]

    return `${date.getDate().toString().padStart(2, "0")}. ${month} ${date.getFullYear()}`
}


// main
const file = process.argv[2]
const out = process.argv[3]
const data = JSON.parse(fs.readFileSync(file).toString()) as InputData
writeDocument(data, out)
