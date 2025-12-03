export const ArticleSchema = {
    author: 'string',          // Author name
    citation: 'string',        // Citation reference
    content: 'string',         // Article content text
    image: 'string',           // Image URL
    link: 'string',            // Article link URL
    source: 'string',          // Source URL
    title: 'string',           // Article title
    createdAt: 'timestamp',    // Auto-generated creation timestamp
    updatedAt: 'timestamp',    // Auto-generated update timestamp
};

export const ARTICLE_FIELDS = [
    'author',
    'citation',
    'content',
    'image',
    'link',
    'source',
    'title',
    'createdAt',
    'updatedAt',
];
