import * as fs from "fs";
import {Document, HeadingLevel, ISectionOptions, Packer, Paragraph, SectionType} from "docx";

interface InputData {
    studentName: string
    subjects: Subject[]
}

interface Subject {
    name: string
    competences: Competence[]
}

interface Competence {
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
            ...data.subjects.map(transformSubject)
        ],
    });

    Packer.toBuffer(doc).then((buffer) => {
        fs.writeFileSync(out, buffer);
    });
}

function transformSubject(subject: Subject) {
    return {
        properties: {
            type: SectionType.CONTINUOUS,
        },
        children: [
            new Paragraph({
                heading: HeadingLevel.HEADING_2,
                text: subject.name
            }),
            ...subject.competences.map(transformCompetences),
            new Paragraph({}),
        ]
    } as ISectionOptions
}

function transformCompetences(competence: Competence) {
    let level = ''
    if (competence.level !== -1) {
        level = `: ${competence.level}/3`
    }

    return new Paragraph({
        bullet: {level: 0},
        text: `${competence.name}${level}`
    })
}

// main
const file = process.argv[2]
const out = process.argv[3]
const data = JSON.parse(fs.readFileSync(file).toString()) as InputData
writeDocument(data, out)
